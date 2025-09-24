const std = @import("std");

pub const Route = struct {
    method: Method,
    path: []const u8,
    handler: *const fn (allocator: std.mem.Allocator, request: []const u8) anyerror![]const u8,
};

pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    OPTIONS,
};

pub fn parseRequest(request: []const u8) ?struct {
    method: Method,
    path: []const u8,
    headers: []const u8,
} {
    var lines = std.mem.splitSequence(u8, request, "\r\n");
    const first_line = lines.next() orelse return null;

    var parts = std.mem.splitSequence(u8, first_line, " ");
    const method_str = parts.next() orelse return null;
    const path = parts.next() orelse return null;

    const method = std.meta.stringToEnum(Method, method_str) orelse return null;

    return .{
        .method = method,
        .path = path,
        .headers = request,
    };
}

pub fn createResponse(status_code: u16, content_type: []const u8, body: []const u8) ![]u8 {
    const status_text = switch (status_code) {
        200 => "OK",
        404 => "Not Found",
        500 => "Internal Server Error",
        else => "Unknown",
    };

    const allocator = std.heap.page_allocator;
    return std.fmt.allocPrint(allocator, "HTTP/1.1 {} {s}\r\nContent-Type: {s}\r\nContent-Length: {}\r\n\r\n{s}", .{ status_code, status_text, content_type, body.len, body });
}
