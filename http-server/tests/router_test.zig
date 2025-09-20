const std = @import("std");
const testing = std.testing;
const router = @import("../src/router.zig");

test "Parse valid GET request" {
    const request = "GET /api/v1/health HTTP/1.1\r\nHost: localhost:8080\r\nUser-Agent: curl/7.68.0\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.GET, parsed.?.method);
    try testing.expectEqualStrings("/api/v1/health", parsed.?.path);
}

test "Parse valid POST request" {
    const request = "POST /api/data HTTP/1.1\r\nHost: localhost:8080\r\nContent-Type: application/json\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.POST, parsed.?.method);
    try testing.expectEqualStrings("/api/data", parsed.?.path);
}

test "Parse valid PUT request" {
    const request = "PUT /api/update HTTP/1.1\r\nHost: localhost:8080\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.PUT, parsed.?.method);
    try testing.expectEqualStrings("/api/update", parsed.?.path);
}

test "Parse valid DELETE request" {
    const request = "DELETE /api/delete HTTP/1.1\r\nHost: localhost:8080\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.DELETE, parsed.?.method);
    try testing.expectEqualStrings("/api/delete", parsed.?.path);
}

test "Parse request with root path" {
    const request = "GET / HTTP/1.1\r\nHost: localhost:8080\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.GET, parsed.?.method);
    try testing.expectEqualStrings("/", parsed.?.path);
}

test "Parse request with query parameters" {
    const request = "GET /api/search?q=test&limit=10 HTTP/1.1\r\nHost: localhost:8080\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.GET, parsed.?.method);
    try testing.expectEqualStrings("/api/search?q=test&limit=10", parsed.?.path);
}

test "Parse invalid request returns null" {
    const request = "INVALID REQUEST FORMAT";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed == null);
}

test "Parse empty request returns null" {
    const request = "";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed == null);
}

test "Parse valid PATCH request" {
    const request = "PATCH /api/update HTTP/1.1\r\nHost: localhost:8080\r\nContent-Type: application/json\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.PATCH, parsed.?.method);
    try testing.expectEqualStrings("/api/update", parsed.?.path);
}

test "Parse valid OPTIONS request" {
    const request = "OPTIONS /api/cors HTTP/1.1\r\nHost: localhost:8080\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed != null);
    try testing.expectEqual(router.Method.OPTIONS, parsed.?.method);
    try testing.expectEqualStrings("/api/cors", parsed.?.path);
}

test "Parse request with unknown method returns null" {
    const request = "UNKNOWN /api/test HTTP/1.1\r\nHost: localhost:8080\r\n\r\n";
    const parsed = router.parseRequest(request);

    try testing.expect(parsed == null);
}

test "Create 200 OK response" {
    const response = try router.createResponse(200, "text/plain", "Hello World");
    defer std.heap.page_allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Type: text/plain") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Length: 11") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Hello World") != null);
}

test "Create 404 Not Found response" {
    const response = try router.createResponse(404, "text/plain", "Not Found");
    defer std.heap.page_allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 404 Not Found") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Type: text/plain") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Not Found") != null);
}

test "Create JSON response" {
    const json_body = "{\"status\":\"ok\"}";
    const response = try router.createResponse(200, "application/json", json_body);
    defer std.heap.page_allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Type: application/json") != null);
    try testing.expect(std.mem.indexOf(u8, response, json_body) != null);
}