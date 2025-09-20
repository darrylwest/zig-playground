const std = @import("std");

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
    _ = try file.readAll(content);

    const mime_type = getMimeType(file_path);
    const response = try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\nContent-Type: {s}\r\nContent-Length: {}\r\n\r\n{s}",
        .{ mime_type, content.len, content }
    );

    allocator.free(content);
    return response;
}

fn getMimeType(file_path: []const u8) []const u8 {
    if (std.mem.endsWith(u8, file_path, ".html")) {
        return "text/html";
    } else if (std.mem.endsWith(u8, file_path, ".css")) {
        return "text/css";
    } else if (std.mem.endsWith(u8, file_path, ".js")) {
        return "application/javascript";
    } else if (std.mem.endsWith(u8, file_path, ".json")) {
        return "application/json";
    } else if (std.mem.endsWith(u8, file_path, ".png")) {
        return "image/png";
    } else if (std.mem.endsWith(u8, file_path, ".jpg") or std.mem.endsWith(u8, file_path, ".jpeg")) {
        return "image/jpeg";
    } else {
        return "text/plain";
    }
}