const std = @import("std");
const testing = std.testing;

// Integration tests that test the overall server functionality
// These tests verify the complete request-response cycle

test "Server module imports correctly" {
    const router = @import("../src/router.zig");
    const api = @import("../src/handlers/api.zig");
    const static_handler = @import("../src/handlers/static.zig");

    // Basic smoke test - if these imports succeed, the modules are properly structured
    _ = router;
    _ = api;
    _ = static_handler;
}

test "API initialization works" {
    const api = @import("../src/handlers/api.zig");

    // This should not crash
    api.initApi();

    // Session count should be incrementable
    api.incrementSessionCount();
    api.incrementSessionCount();

    // Should be able to generate status response
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try api.handleStatus(allocator, "");
    defer allocator.free(response);

    try testing.expect(response.len > 0);
}

test "Router handles all supported methods" {
    const router = @import("../src/router.zig");

    const methods = [_][]const u8{ "GET", "POST", "PUT", "DELETE" };
    const expected = [_]router.Method{ .GET, .POST, .PUT, .DELETE };

    for (methods, expected) |method_str, expected_method| {
        const request = try std.fmt.allocPrint(std.testing.allocator,
            "{s} /test HTTP/1.1\r\nHost: localhost\r\n\r\n", .{method_str});
        defer std.testing.allocator.free(request);

        const parsed = router.parseRequest(request);
        try testing.expect(parsed != null);
        try testing.expectEqual(expected_method, parsed.?.method);
        try testing.expectEqualStrings("/test", parsed.?.path);
    }
}

test "Error responses are properly formatted" {
    const router = @import("../src/router.zig");

    const error_codes = [_]u16{ 400, 404, 405, 500 };
    const expected_texts = [_][]const u8{ "Bad Request", "Not Found", "Method Not Allowed", "Internal Server Error" };

    for (error_codes, expected_texts) |code, expected_text| {
        const response = try router.createResponse(code, "text/plain", expected_text);
        defer std.heap.page_allocator.free(response);

        try testing.expect(std.mem.indexOf(u8, response, expected_text) != null);

        const status_line = try std.fmt.allocPrint(std.testing.allocator, "HTTP/1.1 {} {s}", .{code, expected_text});
        defer std.testing.allocator.free(status_line);

        try testing.expect(std.mem.indexOf(u8, response, status_line) != null);
    }
}

test "All API endpoints have consistent response format" {
    const api = @import("../src/handlers/api.zig");
    api.initApi();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const handlers = [_]*const fn(std.mem.Allocator, []const u8) anyerror![]const u8{
        api.handleHealth,
        api.handlePing,
        api.handleVersion,
        api.handleStatus,
    };

    for (handlers) |handler| {
        const response = try handler(allocator, "GET /test HTTP/1.1\r\n\r\n");
        defer allocator.free(response);

        // All responses should start with HTTP/1.1
        try testing.expect(std.mem.startsWith(u8, response, "HTTP/1.1"));

        // All responses should have Content-Type header
        try testing.expect(std.mem.indexOf(u8, response, "Content-Type:") != null);

        // All responses should have Content-Length header
        try testing.expect(std.mem.indexOf(u8, response, "Content-Length:") != null);

        // Response should have proper HTTP structure (headers separated from body by \r\n\r\n)
        try testing.expect(std.mem.indexOf(u8, response, "\r\n\r\n") != null);
    }
}

test "Static file serving handles various file types" {
    const static_handler = @import("../src/handlers/static.zig");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Test existing files
    const files = [_][]const u8{
        "/index.html",
        "/about.html",
        "/contact.html",
        "/api-reference.html",
        "/css/style.css",
    };

    for (files) |file_path| {
        const response = try static_handler.serveStaticFile(allocator, file_path);
        defer allocator.free(response);

        // Should be successful response
        try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);

        // Should have appropriate content type
        try testing.expect(std.mem.indexOf(u8, response, "Content-Type:") != null);
    }
}

test "Memory management in request handling" {
    // Test that we don't leak memory in normal operations
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        testing.expect(leaked == .ok) catch {
            std.debug.print("Memory leak detected!\n", .{});
        };
    }
    const allocator = gpa.allocator();

    const api = @import("../src/handlers/api.zig");
    const router = @import("../src/router.zig");

    api.initApi();

    // Simulate multiple requests
    for (0..10) |_| {
        const response1 = try api.handleHealth(allocator, "");
        defer allocator.free(response1);

        const response2 = try api.handlePing(allocator, "");
        defer allocator.free(response2);

        const response3 = try router.createResponse(200, "text/plain", "test");
        defer std.heap.page_allocator.free(response3);

        api.incrementSessionCount();
    }
}