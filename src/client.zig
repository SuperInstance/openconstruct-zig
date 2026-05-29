const std = @import("std");
const types = @import("types.zig");
const registry = @import("registry.zig");

const SessionId = types.SessionId;
const AgentIdentity = types.AgentIdentity;
const ModuleDescriptor = types.ModuleDescriptor;
const ModuleFilter = types.ModuleFilter;
const InterfaceChoice = types.InterfaceChoice;
const OnboardingConfig = types.OnboardingConfig;
const ModuleRegistry = registry.ModuleRegistry;

var global_counter: std.atomic.Value(u64) = std.atomic.Value(u64).init(0);

/// Thin client for OpenConstruct onboarding flow
pub const OpenConstructClient = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    session_id: ?SessionId,
    identity: ?AgentIdentity,
    selected_modules: ?[]const []const u8,
    interface_choice: ?InterfaceChoice,
    registry: ModuleRegistry,

    pub fn init() Self {
        return initWithAllocator(std.heap.page_allocator);
    }

    pub fn initWithAllocator(allocator: std.mem.Allocator) Self {
        return .{
            .allocator = allocator,
            .session_id = null,
            .identity = null,
            .selected_modules = null,
            .interface_choice = null,
            .registry = ModuleRegistry.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.selected_modules) |mods| {
            self.allocator.free(mods);
        }
    }

    /// Start a new onboarding session
    pub fn start(self: *Self) !void {
        const cnt = global_counter.fetchAdd(1, .monotonic);
        self.session_id = SessionId.generate(cnt);
    }

    /// Declare the agent identity
    pub fn declareAgent(self: *Self, identity: AgentIdentity) !void {
        if (self.session_id == null) return error.NoActiveSession;
        self.identity = identity;
    }

    /// List available modules, with optional domain filter
    pub fn listModules(self: *Self, filter: ModuleFilter) ![]const ModuleDescriptor {
        if (self.session_id == null) return error.NoActiveSession;
        return try self.registry.listModules(filter);
    }

    /// Select modules for the configuration
    pub fn selectModules(self: *Self, modules: []const []const u8) !void {
        if (self.session_id == null) return error.NoActiveSession;
        if (self.identity == null) return error.AgentNotDeclared;
        const copy = try self.allocator.alloc([]const u8, modules.len);
        @memcpy(copy, modules);
        self.selected_modules = copy;
    }

    /// Choose the interface type
    pub fn chooseInterface(self: *Self, choice: InterfaceChoice) !void {
        if (self.session_id == null) return error.NoActiveSession;
        if (self.selected_modules == null) return error.ModulesNotSelected;
        self.interface_choice = choice;
    }

    /// Generate the final onboarding configuration
    pub fn generateConfig(self: *Self) !OnboardingConfig {
        if (self.session_id == null) return error.NoActiveSession;
        if (self.identity == null) return error.AgentNotDeclared;
        if (self.selected_modules == null) return error.ModulesNotSelected;
        if (self.interface_choice == null) return error.InterfaceNotChosen;

        return OnboardingConfig{
            .session_id = &self.session_id.?.value,
            .agent = self.identity.?,
            .modules = self.selected_modules.?,
            .interface = self.interface_choice.?,
            .generated_at = std.time.timestamp(),
        };
    }
};

test "start creates session" {
    var client = OpenConstructClient.init();
    defer client.deinit();
    try client.start();
    try std.testing.expect(client.session_id != null);
}

test "declareAgent stores identity" {
    var client = OpenConstructClient.init();
    defer client.deinit();
    try client.start();
    const identity = AgentIdentity{
        .name = "test-agent",
        .model = "glm-5.1",
        .capabilities = &.{"code_generation"},
    };
    try client.declareAgent(identity);
    try std.testing.expect(client.identity != null);
    try std.testing.expectEqualStrings("test-agent", client.identity.?.name);
}

test "listModules returns modules" {
    var client = OpenConstructClient.init();
    defer client.deinit();
    try client.start();
    const modules = try client.listModules(.{});
    defer client.allocator.free(modules);
    try std.testing.expect(modules.len > 0);
}

test "listModules filters by domain" {
    var client = OpenConstructClient.init();
    defer client.deinit();
    try client.start();
    const modules = try client.listModules(.{ .domain = "math" });
    defer client.allocator.free(modules);
    for (modules) |m| {
        try std.testing.expectEqualStrings("math", m.domain);
    }
    try std.testing.expect(modules.len >= 2);
}

test "selectModules stores selection" {
    var client = OpenConstructClient.init();
    defer client.deinit();
    try client.start();
    const identity = AgentIdentity{
        .name = "test-agent",
        .model = "glm-5.1",
        .capabilities = &.{},
    };
    try client.declareAgent(identity);
    try client.selectModules(&.{"spectral-graph-core"});
    try std.testing.expect(client.selected_modules != null);
    try std.testing.expectEqual(@as(usize, 1), client.selected_modules.?.len);
    try std.testing.expectEqualStrings("spectral-graph-core", client.selected_modules.?[0]);
}

test "chooseInterface stores choice" {
    var client = OpenConstructClient.init();
    defer client.deinit();
    try client.start();
    const identity = AgentIdentity{ .name = "a", .model = "m", .capabilities = &.{} };
    try client.declareAgent(identity);
    try client.selectModules(&.{"spectral-graph-core"});
    try client.chooseInterface(.rest_api);
    try std.testing.expect(client.interface_choice != null);
    try std.testing.expectEqual(InterfaceChoice.rest_api, client.interface_choice.?);
}

test "generateConfig produces config" {
    var client = OpenConstructClient.init();
    defer client.deinit();
    try client.start();
    const identity = AgentIdentity{
        .name = "my-agent",
        .model = "glm-5.1",
        .capabilities = &.{"code_generation"},
    };
    try client.declareAgent(identity);
    try client.selectModules(&.{"spectral-graph-core", "plato-room"});
    try client.chooseInterface(.websocket);
    const config = try client.generateConfig();
    try std.testing.expectEqualStrings("my-agent", config.agent.name);
    try std.testing.expectEqual(@as(usize, 2), config.modules.len);
    try std.testing.expectEqual(InterfaceChoice.websocket, config.interface);
}

test "full lifecycle" {
    var client = OpenConstructClient.init();
    defer client.deinit();

    try client.start();
    const identity = AgentIdentity{
        .name = "lifecycle-agent",
        .model = "glm-5.1",
        .capabilities = &.{ "code_generation", "web_search" },
    };
    try client.declareAgent(identity);

    const math_mods = try client.listModules(.{ .domain = "math" });
    defer client.allocator.free(math_mods);
    try std.testing.expect(math_mods.len >= 2);

    try client.selectModules(&.{"spectral-graph-core", "plato-room"});
    try client.chooseInterface(.sdk_embedded);

    const config = try client.generateConfig();
    try std.testing.expect(config.generated_at > 0);
    try std.testing.expectEqualStrings("lifecycle-agent", config.agent.name);
    try std.testing.expectEqualStrings("glm-5.1", config.agent.model);
    try std.testing.expectEqual(@as(usize, 2), config.modules.len);
    try std.testing.expectEqual(InterfaceChoice.sdk_embedded, config.interface);
}

test "session ID is unique" {
    var client1 = OpenConstructClient.init();
    defer client1.deinit();
    var client2 = OpenConstructClient.init();
    defer client2.deinit();

    try client1.start();
    try client2.start();

    try std.testing.expect(!std.mem.eql(u8, &client1.session_id.?.value, &client2.session_id.?.value));
}
