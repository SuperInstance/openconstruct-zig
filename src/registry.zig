const std = @import("std");
const types = @import("types.zig");

const ModuleDescriptor = types.ModuleDescriptor;
const ModuleFilter = types.ModuleFilter;

/// Built-in module catalog
pub const BUILTIN_MODULES = [_]ModuleDescriptor{
    .{ .name = "spectral-graph-core", .domain = "math", .version = "1.0.0", .description = "Spectral graph theory primitives" },
    .{ .name = "plato-room", .domain = "math", .version = "2.1.0", .description = "Platonic solid geometry and room acoustics" },
    .{ .name = "vector-embeddings", .domain = "ml", .version = "0.9.2", .description = "Dense vector embedding utilities" },
    .{ .name = "tensor-ops", .domain = "math", .version = "3.0.1", .description = "Tensor algebra operations" },
    .{ .name = "nlp-tokenizer", .domain = "nlp", .version = "1.2.0", .description = "Tokenizer for natural language processing" },
    .{ .name = "knowledge-graph", .domain = "knowledge", .version = "0.5.0", .description = "Knowledge graph construction and queries" },
    .{ .name = "web-crawler", .domain = "web", .version = "1.1.0", .description = "Web crawling and scraping" },
    .{ .name = "sentiment-analyzer", .domain = "nlp", .version = "0.8.0", .description = "Sentiment analysis module" },
};

/// Module registry with domain filtering
pub const ModuleRegistry = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{ .allocator = allocator };
    }

    /// List modules, optionally filtering by domain
    pub fn listModules(self: *Self, filter: ModuleFilter) ![]const ModuleDescriptor {
        if (filter.domain) |domain| {
            var count: usize = 0;
            for (&BUILTIN_MODULES) |*m| {
                if (std.mem.eql(u8, m.domain, domain)) count += 1;
            }
            const result = try self.allocator.alloc(ModuleDescriptor, count);
            var idx: usize = 0;
            for (&BUILTIN_MODULES) |*m| {
                if (std.mem.eql(u8, m.domain, domain)) {
                    result[idx] = m.*;
                    idx += 1;
                }
            }
            return result;
        }
        const result = try self.allocator.alloc(ModuleDescriptor, BUILTIN_MODULES.len);
        @memcpy(result, &BUILTIN_MODULES);
        return result;
    }
};
