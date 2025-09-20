const std = @import("std");

pub const LogLevel = enum {
    DEBUG,
    INFO,
    WARN,
    ERROR,

    pub fn toString(self: LogLevel) []const u8 {
        return switch (self) {
            .DEBUG => "DEBUG",
            .INFO => "INFO",
            .WARN => "WARN",
            .ERROR => "ERROR",
        };
    }
};

pub fn log(level: LogLevel, comptime fmt: []const u8, args: anytype) void {
    const timestamp = std.time.timestamp();
    const level_str = level.toString();

    // Create a simple timestamp (seconds since epoch for now)
    std.debug.print("[{}] [{s}] ", .{ timestamp, level_str });
    std.debug.print(fmt ++ "\n", args);
}

pub fn logRequest(method: []const u8, path: []const u8, status_code: u16) void {
    log(.INFO, "{s} {s} -> {}", .{ method, path, status_code });
}

pub fn logError(error_msg: []const u8, err: anyerror) void {
    log(.ERROR, "{s}: {any}", .{ error_msg, err });
}

pub fn logServerStart(port: u16) void {
    log(.INFO, "HTTP server starting on port {}", .{port});
}

pub fn logConnection(client_address: []const u8) void {
    log(.DEBUG, "New connection from {s}", .{client_address});
}