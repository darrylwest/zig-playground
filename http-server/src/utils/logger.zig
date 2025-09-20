const std = @import("std");

pub const LogLevel = enum(u8) {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,

    pub fn toString(self: LogLevel) []const u8 {
        return switch (self) {
            .DEBUG => "DEBUG",
            .INFO => "INFO",
            .WARN => "WARN",
            .ERROR => "ERROR",
        };
    }

    pub fn fromString(level_str: []const u8) LogLevel {
        if (std.mem.eql(u8, level_str, "DEBUG")) return .DEBUG;
        if (std.mem.eql(u8, level_str, "INFO")) return .INFO;
        if (std.mem.eql(u8, level_str, "WARN")) return .WARN;
        if (std.mem.eql(u8, level_str, "ERROR")) return .ERROR;
        return .INFO; // Default fallback
    }
};

var current_log_level: LogLevel = .INFO;

pub fn setLogLevel(level: LogLevel) void {
    current_log_level = level;
}

pub fn setLogLevelFromString(level_str: []const u8) void {
    current_log_level = LogLevel.fromString(level_str);
}

pub fn log(level: LogLevel, comptime fmt: []const u8, args: anytype) void {
    // Only log if the message level is at or above the current log level
    if (@intFromEnum(level) < @intFromEnum(current_log_level)) {
        return;
    }

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