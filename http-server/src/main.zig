const std = @import("std");
const router = @import("router.zig");
const api = @import("handlers/api.zig");
const static = @import("handlers/static.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize API
    api.initApi();

    const address = std.net.Address.parseIp("127.0.0.1", 8080) catch unreachable;
    var listener = try address.listen(.{ .reuse_address = true });
    defer listener.deinit();

    std.debug.print("HTTP server running on http://127.0.0.1:8080\n", .{});

    while (true) {
        const connection = try listener.accept();
        defer connection.stream.close();

        api.incrementSessionCount();

        handleConnection(allocator, connection) catch |err| {
            std.debug.print("Error handling connection: {}\n", .{err});
        };
    }
}

fn handleConnection(allocator: std.mem.Allocator, connection: std.net.Server.Connection) !void {
    var read_buffer: [8192]u8 = undefined;
    const bytes_read = try connection.stream.read(&read_buffer);
    const request = read_buffer[0..bytes_read];

    const parsed = router.parseRequest(request) orelse {
        const error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nContent-Length: 15\r\n\r\n400 Bad Request";
        try connection.stream.writeAll(error_response);
        return;
    };

    var response: []const u8 = undefined;
    var should_free = true;

    if (parsed.method == .GET) {
        if (std.mem.eql(u8, parsed.path, "/api/v1/health")) {
            response = try api.handleHealth(allocator, request);
        } else if (std.mem.eql(u8, parsed.path, "/api/v1/ping")) {
            response = try api.handlePing(allocator, request);
        } else if (std.mem.eql(u8, parsed.path, "/api/v1/version")) {
            response = try api.handleVersion(allocator, request);
        } else if (std.mem.eql(u8, parsed.path, "/api/v1/status")) {
            response = try api.handleStatus(allocator, request);
        } else if (std.mem.eql(u8, parsed.path, "/")) {
            response = try static.serveStaticFile(allocator, "/index.html");
        } else {
            // Try to serve as static file
            response = try static.serveStaticFile(allocator, parsed.path);
        }
    } else {
        response = "HTTP/1.1 405 Method Not Allowed\r\nContent-Type: text/plain\r\nContent-Length: 18\r\n\r\n405 Method Not Allowed";
        should_free = false;
    }

    try connection.stream.writeAll(response);

    if (should_free) {
        allocator.free(response);
    }
}
