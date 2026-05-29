const std = @import("std");

/// Unique session identifier
pub const SessionId = struct {
    value: [36]u8,
    counter: u64,

    pub fn generate(counter: u64) SessionId {
        var buf: [36]u8 = undefined;
        const hex = "0123456789abcdef";
        var rng = std.Random.DefaultPrng.init(counter);
        const rand = rng.random();
        var i: usize = 0;
        while (i < 32) : (i += 1) {
            const byte = rand.int(u8);
            switch (i) {
                8, 13, 18, 23 => {
                    buf[i] = '-';
                    if (i < 32) buf[i + 1] = hex[byte >> 4];
                    if (i + 1 < 32) buf[i + 2] = hex[byte & 0x0f];
                    i += 2;
                },
                else => {
                    buf[i] = hex[byte >> 4];
                },
            }
        }
        return SessionId{ .value = buf, .counter = counter };
    }

    pub fn format(self: SessionId, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.writeAll(&self.value);
    }
};

/// Agent self-declaration identity
pub const AgentIdentity = struct {
    name: []const u8,
    model: []const u8,
    capabilities: []const []const u8,
};

/// A module descriptor in the registry
pub const ModuleDescriptor = struct {
    name: []const u8,
    domain: []const u8,
    version: []const u8,
    description: []const u8,
};

/// Filter options for listing modules
pub const ModuleFilter = struct {
    domain: ?[]const u8 = null,
};

/// Interface choice for the onboarding config
pub const InterfaceChoice = enum {
    rest_api,
    websocket,
    cli,
    sdk_embedded,

    pub fn toString(self: InterfaceChoice) []const u8 {
        return switch (self) {
            .rest_api => "rest-api",
            .websocket => "websocket",
            .cli => "cli",
            .sdk_embedded => "sdk-embedded",
        };
    }
};

/// The final onboarding configuration output
pub const OnboardingConfig = struct {
    session_id: []const u8,
    agent: AgentIdentity,
    modules: []const []const u8,
    interface: InterfaceChoice,
    generated_at: i64,
};
