const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Find all .zig files in the current directory, excluding build.zig
    var dir = std.fs.cwd().openDir(".", .{ .iterate = true }) catch return;
    defer dir.close();

    var iterator = dir.iterate();
    var zig_files = std.ArrayList([]const u8).empty;
    defer zig_files.deinit(b.allocator);

    while (iterator.next() catch return) |entry| {
        if (entry.kind == .file and
            std.mem.endsWith(u8, entry.name, ".zig") and
            !std.mem.eql(u8, entry.name, "build.zig")) {
            const owned_name = b.allocator.dupe(u8, entry.name) catch return;
            zig_files.append(b.allocator, owned_name) catch return;
        }
    }

    // Create executables for each .zig file
    for (zig_files.items) |file| {
        const name = std.fs.path.stem(file);

        const exe = b.addExecutable(.{
            .name = name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(file),
                .target = target,
                .optimize = optimize,
            }),
        });

        // Install to bin/
        const install_exe = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = .{ .custom = "bin" } },
        });

        b.getInstallStep().dependOn(&install_exe.step);
    }
}
