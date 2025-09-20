const std = @import("std");
const router = @import("router.zig");
const api = @import("handlers/api.zig");
const static = @import("handlers/static.zig");
const logger = @import("utils/logger.zig");

const DEFAULT_PORT = 8080;
const DEFAULT_HOST = "127.0.0.1";

const Config = struct {
    host: []const u8,
    port: u16,

    fn deinit(self: *const Config, allocator: std.mem.Allocator) void {
        if (self.host.ptr != DEFAULT_HOST.ptr) {
            allocator.free(self.host);
        }
    }
};

const ServerConfig = struct {
    host: []const u8 = DEFAULT_HOST,
    port: u16 = DEFAULT_PORT,
};

const LoggingConfig = struct {
    level: []const u8 = "INFO",
};

const JsonConfig = struct {
    server: ServerConfig = .{},
    logging: LoggingConfig = .{},
};

fn parseConfigFromJson(allocator: std.mem.Allocator, config_path: []const u8) !Config {
    const file = std.fs.cwd().openFile(config_path, .{}) catch |err| switch (err) {
        error.FileNotFound => {
            logger.log(.INFO, "Config file '{s}' not found, using defaults", .{config_path});
            return Config{
                .host = try allocator.dupe(u8, DEFAULT_HOST),
                .port = DEFAULT_PORT,
            };
        },
        else => return err,
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const contents = try allocator.alloc(u8, file_size);
    defer allocator.free(contents);
    _ = try file.readAll(contents);

    const parsed = std.json.parseFromSlice(JsonConfig, allocator, contents, .{}) catch |err| {
        logger.log(.ERROR, "Failed to parse config file '{s}': {}", .{ config_path, err });
        return err;
    };
    defer parsed.deinit();

    const json_config = parsed.value;

    logger.log(.INFO, "Loaded configuration from '{s}'", .{config_path});
    logger.log(.INFO, "  Host: {s}", .{json_config.server.host});
    logger.log(.INFO, "  Port: {}", .{json_config.server.port});

    return Config{
        .host = try allocator.dupe(u8, json_config.server.host),
        .port = json_config.server.port,
    };
}

fn parseConfig(allocator: std.mem.Allocator) !Config {
    // Try to load from config file first
    const config_file = "config.json";
    return parseConfigFromJson(allocator, config_file);
}

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

    // Parse configuration
    const config = parseConfig(allocator) catch |err| {
        logger.log(.ERROR, "Failed to parse configuration", .{});
        return err;
    };
    defer config.deinit(allocator);

    // Log version on startup
    const version = api.parseVersionFromZon(allocator) catch "unknown";
    defer allocator.free(version);
    logger.log(.INFO, "HTTP Server, Version: {s}", .{version});

    const address = std.net.Address.parseIp(config.host, config.port) catch |err| {
        logger.log(.ERROR, "Failed to parse server address {}:{s}", .{ config.port, config.host });
        return err;
    };

    var listener = address.listen(.{ .reuse_address = true }) catch |err| {
        logger.log(.ERROR, "Failed to bind to {}:{s}", .{ config.port, config.host });
        return err;
    };
    defer listener.deinit();

    logger.logServerStart(config.port);
    std.debug.print("HTTP server running on http://{s}:{}\n", .{ config.host, config.port });

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
