const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // List of .zig files to compile
    const zig_files = [_][]const u8{
        "hello.zig",
        "string_literals.zig",
        "values.zig",
    };

    // Create executables for each .zig file
    for (zig_files) |file| {
        const name = std.fs.path.stem(file);

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(file),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Install to zig-bin/bin/
        const install_exe = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = .{ .custom = "zig-bin/bin" } },
        });

        b.getInstallStep().dependOn(&install_exe.step);
    }
}