const std = @import("std");
const router = @import("router.zig");
const api = @import("handlers/api.zig");
const static = @import("handlers/static.zig");
const logger = @import("utils/logger.zig");

const SERVER_PORT = 8080;
const SERVER_HOST = "127.0.0.1";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked == .leak) {
            logger.log(.WARN, "Memory leak detected during shutdown", .{});
        }
    }
    const allocator = gpa.allocator();

    // Initialize API
    api.initApi();
    logger.log(.INFO, "API handlers initialized", .{});

    // Log version on startup
    const version = api.parseVersionFromZon(allocator) catch "unknown";
    defer allocator.free(version);
    logger.log(.INFO, "HTTP Server, Version: {s}", .{version});

    const address = std.net.Address.parseIp(SERVER_HOST, SERVER_PORT) catch |err| {
        logger.log(.ERROR, "Failed to parse server address", .{});
        return err;
    };

    var listener = address.listen(.{ .reuse_address = true }) catch |err| {
        logger.log(.ERROR, "Failed to bind to address", .{});
        return err;
    };
    defer listener.deinit();

    logger.logServerStart(SERVER_PORT);
    std.debug.print("HTTP server running on http://{s}:{}\n", .{ SERVER_HOST, SERVER_PORT });

    while (true) {
        const connection = listener.accept() catch {
            logger.log(.ERROR, "Failed to accept connection", .{});
            continue;
        };
        defer connection.stream.close();

        api.incrementSessionCount();

        // Log new connection
        logger.log(.DEBUG, "New connection accepted", .{});

        handleConnection(allocator, connection) catch {
            logger.log(.ERROR, "Error handling connection", .{});
        };
    }
}

fn handleConnection(allocator: std.mem.Allocator, connection: std.net.Server.Connection) !void {
    var read_buffer: [8192]u8 = undefined;

    const bytes_read = connection.stream.read(&read_buffer) catch |err| {
        logger.log(.ERROR, "Failed to read from connection", .{});
        return err;
    };

    if (bytes_read == 0) {
        logger.log(.WARN, "Received empty request", .{});
        return;
    }

    const request = read_buffer[0..bytes_read];

    const parsed = router.parseRequest(request) orelse {
        const error_response = "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\nContent-Length: 15\r\n\r\n400 Bad Request";
        connection.stream.writeAll(error_response) catch {
            logger.log(.ERROR, "Failed to send 400 response", .{});
        };
        logger.log(.INFO, "Invalid request received", .{});
        return;
    };

    var response: []const u8 = undefined;
    var should_free = true;
    var status_code: u16 = 200;

    if (parsed.method == .GET) {
        if (std.mem.eql(u8, parsed.path, "/api/v1/health")) {
            response = api.handleHealth(allocator, request) catch blk: {
                logger.log(.ERROR, "Failed to handle health endpoint", .{});
                should_free = false;
                status_code = 500;
                break :blk "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: 21\r\n\r\n500 Internal Server Error";
            };
        } else if (std.mem.eql(u8, parsed.path, "/api/v1/ping")) {
            response = api.handlePing(allocator, request) catch blk: {
                logger.log(.ERROR, "Failed to handle ping endpoint", .{});
                should_free = false;
                status_code = 500;
                break :blk "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: 21\r\n\r\n500 Internal Server Error";
            };
        } else if (std.mem.eql(u8, parsed.path, "/api/v1/version")) {
            response = api.handleVersion(allocator, request) catch blk: {
                logger.log(.ERROR, "Failed to handle version endpoint", .{});
                should_free = false;
                status_code = 500;
                break :blk "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: 21\r\n\r\n500 Internal Server Error";
            };
        } else if (std.mem.eql(u8, parsed.path, "/api/v1/status")) {
            response = api.handleStatus(allocator, request) catch blk: {
                logger.log(.ERROR, "Failed to handle status endpoint", .{});
                should_free = false;
                status_code = 500;
                break :blk "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: 21\r\n\r\n500 Internal Server Error";
            };
        } else if (std.mem.eql(u8, parsed.path, "/")) {
            response = static.serveStaticFile(allocator, "/index.html") catch blk: {
                logger.log(.ERROR, "Failed to serve index.html", .{});
                should_free = false;
                status_code = 500;
                break :blk "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: 21\r\n\r\n500 Internal Server Error";
            };
            // Check if it's a 404 response
            if (std.mem.indexOf(u8, response, "404 Not Found") != null) {
                status_code = 404;
            }
        } else {
            // Try to serve as static file
            response = static.serveStaticFile(allocator, parsed.path) catch blk: {
                logger.log(.ERROR, "Failed to serve static file", .{});
                should_free = false;
                status_code = 500;
                break :blk "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\nContent-Length: 21\r\n\r\n500 Internal Server Error";
            };
            // Check if it's a 404 response
            if (std.mem.indexOf(u8, response, "404 Not Found") != null) {
                status_code = 404;
            }
        }
    } else {
        response = "HTTP/1.1 405 Method Not Allowed\r\nContent-Type: text/plain\r\nContent-Length: 18\r\n\r\n405 Method Not Allowed";
        should_free = false;
        status_code = 405;
    }

    connection.stream.writeAll(response) catch |err| {
        logger.log(.ERROR, "Failed to send response", .{});
        if (should_free) {
            allocator.free(response);
        }
        return err;
    };

    // Log the request
    logger.log(.INFO, "Request processed", .{});

    if (should_free) {
        allocator.free(response);
    }
}
