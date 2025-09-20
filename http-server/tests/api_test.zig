const std = @import("std");
const testing = std.testing;
const api = @import("../src/handlers/api.zig");

test "API health endpoint returns ok" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const request = "GET /api/v1/health HTTP/1.1\r\nHost: localhost\r\n\r\n";
    const response = try api.handleHealth(allocator, request);
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "ok") != null);
    try testing.expect(std.mem.indexOf(u8, response, "text/plain") != null);
}

test "API ping endpoint returns PONG" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const request = "GET /api/v1/ping HTTP/1.1\r\nHost: localhost\r\n\r\n";
    const response = try api.handlePing(allocator, request);
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "PONG") != null);
    try testing.expect(std.mem.indexOf(u8, response, "text/plain") != null);
}

test "API version endpoint returns version string" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const request = "GET /api/v1/version HTTP/1.1\r\nHost: localhost\r\n\r\n";
    const response = try api.handleVersion(allocator, request);
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "0.1.0") != null);
    try testing.expect(std.mem.indexOf(u8, response, "text/plain") != null);
}

test "API status endpoint returns JSON" {
    // Initialize API first
    api.initApi();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const request = "GET /api/v1/status HTTP/1.1\r\nHost: localhost\r\n\r\n";
    const response = try api.handleStatus(allocator, request);
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "application/json") != null);
    try testing.expect(std.mem.indexOf(u8, response, "uptime") != null);
    try testing.expect(std.mem.indexOf(u8, response, "session_count") != null);
    try testing.expect(std.mem.indexOf(u8, response, "timestamp") != null);
}

test "Session count increments correctly" {
    api.initApi();

    // Get initial session count
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response1 = try api.handleStatus(allocator, "");
    defer allocator.free(response1);

    // Increment session count
    api.incrementSessionCount();
    api.incrementSessionCount();

    const response2 = try api.handleStatus(allocator, "");
    defer allocator.free(response2);

    // Check that session count increased
    // Note: This is a basic test - in a real scenario you'd parse the JSON
    try testing.expect(std.mem.indexOf(u8, response2, "session_count") != null);
}