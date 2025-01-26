const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "opengl",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.linkSystemLibrary("opengl32");
    exe.linkSystemLibrary("glu32");
    exe.linkSystemLibrary("glew32");
    exe.linkSystemLibrary("glfw3");

    exe.addIncludePath(.{ .cwd_relative = "C:\\MinGW\\include" });
    exe.addLibraryPath(.{ .cwd_relative = "C:\\MinGW\\lib" });

    exe.addRPath(b.path("src/"));

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
