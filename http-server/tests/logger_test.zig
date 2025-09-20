const std = @import("std");
const testing = std.testing;
const logger = @import("../src/utils/logger.zig");

test "LogLevel toString returns correct strings" {
    try testing.expectEqualStrings("DEBUG", logger.LogLevel.DEBUG.toString());
    try testing.expectEqualStrings("INFO", logger.LogLevel.INFO.toString());
    try testing.expectEqualStrings("WARN", logger.LogLevel.WARN.toString());
    try testing.expectEqualStrings("ERROR", logger.LogLevel.ERROR.toString());
}

test "Logger functions execute without crashing" {
    // These tests verify that logging functions don't crash
    // In a real application, you might redirect output to test the actual log content

    logger.log(.DEBUG, "Debug message test", .{});
    logger.log(.INFO, "Info message test", .{});
    logger.log(.WARN, "Warning message test", .{});
    logger.log(.ERROR, "Error message test", .{});
}

test "Logger handles formatted messages" {
    // Test that logger can handle formatted strings with arguments
    logger.log(.INFO, "Test with number: {}", .{42});
    logger.log(.WARN, "Test with string: {s}", .{"hello"});
    logger.log(.ERROR, "Test with multiple args: {} {s} {}", .{ 1, "test", 3.14 });
}

test "logServerStart function works" {
    logger.logServerStart(8080);
    logger.logServerStart(3000);
    logger.logServerStart(443);
}

test "logConnection function works" {
    logger.logConnection("127.0.0.1:8080");
    logger.logConnection("192.168.1.1:3000");
    logger.logConnection("localhost:8000");
}

test "logRequest function works" {
    logger.logRequest("GET", "/", 200);
    logger.logRequest("POST", "/api/data", 201);
    logger.logRequest("GET", "/nonexistent", 404);
    logger.logRequest("PUT", "/api/update", 500);
}

test "logError function works" {
    logger.logError("Test error", error.TestError);
    logger.logError("Network error", error.NetworkUnreachable);
    logger.logError("File not found", error.FileNotFound);
}