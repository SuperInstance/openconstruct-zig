const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.addModule("openconstruct", .{
        .root_source_file = b.path("src/openconstruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    _ = lib_mod;

    const lib = b.addStaticLibrary(.{
        .name = "openconstruct",
        .root_source_file = b.path("src/openconstruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(lib);

    const tests = b.addTest(.{
        .root_source_file = b.path("src/openconstruct.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);
    run_tests.has_side_effects = false;

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&run_tests.step);
}
