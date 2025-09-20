const std = @import("std");
const api = @import("api.zig");

pub fn serveStaticFile(allocator: std.mem.Allocator, file_path: []const u8) ![]const u8 {
    const full_path = try std.fmt.allocPrint(allocator, "static{s}", .{file_path});
    defer allocator.free(full_path);

    const file = std.fs.cwd().openFile(full_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            return try allocator.dupe(u8, "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\n404 Not Found");
        },
        else => return err,
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const content = try allocator.alloc(u8, file_size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    const mime_type = getMimeType(file_path);

    // Process HTML files to replace version placeholder
    const processed_content = if (std.mem.endsWith(u8, file_path, ".html")) blk: {
        const version = api.parseVersionFromZon(allocator) catch "unknown";
        defer allocator.free(version);

        // Replace {{VERSION}} placeholder with actual version
        if (std.mem.indexOf(u8, content, "{{VERSION}}")) |_| {
            break :blk try std.mem.replaceOwned(u8, allocator, content, "{{VERSION}}", version);
        } else {
            break :blk try allocator.dupe(u8, content);
        }
    } else try allocator.dupe(u8, content);
    defer allocator.free(processed_content);

    const response = try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {}\r\n\r\n{s}",
        .{ mime_type, processed_content.len, processed_content }
    );

    return response;
}

const FileExtension = enum {
    html,
    css,
    js,
    json,
    png,
    jpg,
    jpeg,

    fn getMimeType(self: FileExtension) []const u8 {
        return switch (self) {
            .html => "text/html",
            .css => "text/css",
            .js => "application/javascript",
            .json => "application/json",
            .png => "image/png",
            .jpg, .jpeg => "image/jpeg",
        };
    }
};

fn getFileExtension(file_path: []const u8) ?[]const u8 {
    if (std.mem.lastIndexOf(u8, file_path, ".")) |dot_index| {
        return file_path[dot_index + 1..];
    }
    return null;
}

fn getMimeType(file_path: []const u8) []const u8 {
    const extension = getFileExtension(file_path) orelse return "text/plain";

    if (std.meta.stringToEnum(FileExtension, extension)) |ext| {
        return ext.getMimeType();
    }

    return "text/plain";
}