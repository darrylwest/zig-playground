const std = @import("std");
const testing = std.testing;
const router = @import("../src/router.zig");
const static_handler = @import("../src/handlers/static.zig");
const api = @import("../src/handlers/api.zig");

test "Router handles malformed HTTP requests" {
    const malformed_requests = [_][]const u8{
        "",
        "INVALID",
        "GET",
        "GET /",
        "GET / HTTP/1.1",
        "INVALID_METHOD / HTTP/1.1\r\n\r\n",
        "\r\n\r\n",
        "GET\r\n",
        "GET /path\r\n",
        " GET / HTTP/1.1\r\n\r\n",
    };

    for (malformed_requests) |request| {
        const parsed = router.parseRequest(request);
        // All malformed requests should return null
        try testing.expect(parsed == null);
    }
}

test "Router handles extremely long paths" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a very long path (4KB)
    const long_path = try allocator.alloc(u8, 4096);
    defer allocator.free(long_path);
    @memset(long_path, 'a');

    const request = try std.fmt.allocPrint(allocator, "GET /{s} HTTP/1.1\r\nHost: localhost\r\n\r\n", .{long_path});
    defer allocator.free(request);

    const parsed = router.parseRequest(request);
    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.GET, parsed.?.method);
}

test "Router handles requests with special characters" {
    const special_requests = [_][]const u8{
        "GET /%20space HTTP/1.1\r\n\r\n",
        "GET /path?query=value&other=test HTTP/1.1\r\n\r\n",
        "GET /path#fragment HTTP/1.1\r\n\r\n",
        "GET /path/to/file.html HTTP/1.1\r\n\r\n",
        "GET /api/v1/users/123 HTTP/1.1\r\n\r\n",
    };

    for (special_requests) |request| {
        const parsed = router.parseRequest(request);
        try testing.expect(parsed != null);
        try testing.expectEqual(router.Method.GET, parsed.?.method);
    }
}

test "Static file handler with directory traversal attempts" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const dangerous_paths = [_][]const u8{
        "/../etc/passwd",
        "/../../etc/shadow",
        "/../../../windows/system32/config/sam",
        "/./../../etc/hosts",
        "/static/../../../etc/passwd",
        "/\x00/etc/passwd",
    };

    for (dangerous_paths) |path| {
        const response = try static_handler.serveStaticFile(allocator, path);
        defer allocator.free(response);

        // Should return 404 or 500, not serve sensitive files
        const is_error = std.mem.indexOf(u8, response, "404 Not Found") != null or
                        std.mem.indexOf(u8, response, "500 Internal Server Error") != null;
        try testing.expect(is_error);
    }
}

test "Static file handler with extremely long filenames" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a very long filename
    const long_filename = try allocator.alloc(u8, 1000);
    defer allocator.free(long_filename);
    @memset(long_filename, 'x');

    const long_path = try std.fmt.allocPrint(allocator, "/{s}.html", .{long_filename});
    defer allocator.free(long_path);

    const response = try static_handler.serveStaticFile(allocator, long_path);
    defer allocator.free(response);

    // Should handle gracefully (likely 404)
    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1") != null);
}

test "Router createResponse with invalid status codes" {
    // Test edge case status codes
    const response_999 = try router.createResponse(999, "text/plain", "Unknown status");
    defer std.heap.page_allocator.free(response_999);

    try testing.expect(std.mem.indexOf(u8, response_999, "HTTP/1.1 999 Unknown") != null);

    const response_0 = try router.createResponse(0, "text/plain", "Zero status");
    defer std.heap.page_allocator.free(response_0);

    try testing.expect(std.mem.indexOf(u8, response_0, "HTTP/1.1 0 Unknown") != null);
}

test "Router createResponse with empty content" {
    const response = try router.createResponse(200, "text/plain", "");
    defer std.heap.page_allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Length: 0") != null);
}

test "Router createResponse with very large content" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create large content (1MB)
    const large_content = try allocator.alloc(u8, 1024 * 1024);
    defer allocator.free(large_content);
    @memset(large_content, 'A');

    const response = try router.createResponse(200, "text/plain", large_content);
    defer std.heap.page_allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Length: 1048576") != null);
}

test "API handlers with invalid input data" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize API
    api.initApi();

    // Test with empty requests
    const empty_response = try api.handleHealth(allocator, "");
    defer allocator.free(empty_response);
    try testing.expect(std.mem.indexOf(u8, empty_response, "200 OK") != null);

    // Test with malformed requests
    const malformed_request = "INVALID REQUEST DATA\x00\xFF";
    const malformed_response = try api.handlePing(allocator, malformed_request);
    defer allocator.free(malformed_response);
    try testing.expect(std.mem.indexOf(u8, malformed_response, "PONG") != null);

    // Test status endpoint multiple times to verify consistency
    for (0..5) |_| {
        const status_response = try api.handleStatus(allocator, "");
        defer allocator.free(status_response);
        try testing.expect(std.mem.indexOf(u8, status_response, "application/json") != null);
        try testing.expect(std.mem.indexOf(u8, status_response, "uptime") != null);
    }
}

test "Memory allocation failure simulation" {
    var failing_allocator = testing.FailingAllocator.init(testing.allocator, .{ .fail_index = 0 });
    const allocator = failing_allocator.allocator();

    // These should fail gracefully when memory allocation fails
    const result = api.handleHealth(allocator, "GET /health HTTP/1.1\r\n\r\n");
    try testing.expectError(error.OutOfMemory, result);
}

test "Concurrent session counting" {
    api.initApi();

    // Simulate rapid session increments
    for (0..1000) |_| {
        api.incrementSessionCount();
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try api.handleStatus(allocator, "");
    defer allocator.free(response);

    // Should contain a large session count
    try testing.expect(std.mem.indexOf(u8, response, "session_count") != null);
}