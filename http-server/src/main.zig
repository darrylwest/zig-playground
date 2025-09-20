const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const address = std.net.Address.parseIp("127.0.0.1", 8080) catch unreachable;
    var listener = try address.listen(.{ .reuse_address = true });
    defer listener.deinit();

    std.debug.print("HTTP server running on http://127.0.0.1:8080\n", .{});

    while (true) {
        const connection = try listener.accept();
        defer connection.stream.close();

        handleConnection(allocator, connection) catch |err| {
            std.debug.print("Error handling connection: {}\n", .{err});
        };
    }
}

fn handleConnection(_: std.mem.Allocator, connection: std.net.Server.Connection) !void {
    var read_buffer: [8192]u8 = undefined;
    _ = try connection.stream.read(&read_buffer);

    // Simple HTTP response
    const response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: 79\r\n\r\n<html><body><h1>Welcome to Zig HTTP Server!</h1><p>Server is running.</p></body></html>";

    try connection.stream.writeAll(response);
}
