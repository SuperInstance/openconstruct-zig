//! # OpenConstruct — Zig Binding
//!
//! Thin client for OpenConstruct onboarding flow.
//! Provides a structured phase-based API for agent configuration.

pub const client = @import("client.zig");
pub const registry = @import("registry.zig");
pub const types = @import("types.zig");

pub const OpenConstructClient = client.OpenConstructClient;
pub const AgentIdentity = types.AgentIdentity;
pub const ModuleDescriptor = types.ModuleDescriptor;
pub const ModuleFilter = types.ModuleFilter;
pub const InterfaceChoice = types.InterfaceChoice;
pub const OnboardingConfig = types.OnboardingConfig;
pub const ModuleRegistry = registry.ModuleRegistry;

test {
    _ = @import("client.zig");
}
