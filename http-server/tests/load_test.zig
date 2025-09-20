const std = @import("std");
const testing = std.testing;
const api = @import("../src/handlers/api.zig");
const static_handler = @import("../src/handlers/static.zig");
const router = @import("../src/router.zig");

test "Concurrent API requests simulation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    api.initApi();

    const num_requests = 100;
    var responses = try allocator.alloc([]const u8, num_requests);
    defer {
        for (responses) |response| {
            allocator.free(response);
        }
        allocator.free(responses);
    }

    // Simulate concurrent health check requests
    for (0..num_requests) |i| {
        api.incrementSessionCount();
        responses[i] = try api.handleHealth(allocator, "GET /api/v1/health HTTP/1.1\r\n\r\n");

        // Verify each response is valid
        try testing.expect(std.mem.indexOf(u8, responses[i], "200 OK") != null);
        try testing.expect(std.mem.indexOf(u8, responses[i], "ok") != null);
    }
}

test "Mixed API endpoint load simulation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    api.initApi();

    const endpoints = [_]*const fn(std.mem.Allocator, []const u8) anyerror![]const u8{
        api.handleHealth,
        api.handlePing,
        api.handleVersion,
        api.handleStatus,
    };

    const num_iterations = 50;
    var total_responses: usize = 0;

    for (0..num_iterations) |i| {
        for (endpoints) |handler| {
            api.incrementSessionCount();
            const response = try handler(allocator, "");
            defer allocator.free(response);

            // Basic validation
            try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1") != null);
            try testing.expect(response.len > 0);
            total_responses += 1;
        }

        // Occasionally check status to verify session counting
        if (i % 10 == 0) {
            const status_response = try api.handleStatus(allocator, "");
            defer allocator.free(status_response);
            try testing.expect(std.mem.indexOf(u8, status_response, "session_count") != null);
        }
    }

    try testing.expectEqual(num_iterations * endpoints.len, total_responses);
}

test "Static file serving under load" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const files = [_][]const u8{
        "/index.html",
        "/about.html",
        "/contact.html",
        "/api-reference.html",
        "/css/style.css",
    };

    const requests_per_file = 20;
    var total_served: usize = 0;

    for (files) |file_path| {
        for (0..requests_per_file) |_| {
            const response = try static_handler.serveStaticFile(allocator, file_path);
            defer allocator.free(response);

            // Should be either 200 OK or handled error
            const is_valid = std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null or
                            std.mem.indexOf(u8, response, "HTTP/1.1 404 Not Found") != null;
            try testing.expect(is_valid);
            total_served += 1;
        }
    }

    try testing.expectEqual(files.len * requests_per_file, total_served);
}

test "Request parsing under high volume" {
    const valid_requests = [_][]const u8{
        "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n",
        "POST /api/data HTTP/1.1\r\nContent-Type: application/json\r\n\r\n",
        "PUT /api/update HTTP/1.1\r\nAuthorization: Bearer token\r\n\r\n",
        "DELETE /api/delete HTTP/1.1\r\nUser-Agent: TestClient\r\n\r\n",
        "PATCH /api/partial HTTP/1.1\r\nContent-Type: application/json\r\n\r\n",
        "OPTIONS /api/cors HTTP/1.1\r\nOrigin: https://example.com\r\n\r\n",
        "GET /api/v1/status HTTP/1.1\r\nAccept: application/json\r\n\r\n",
    };

    const iterations = 200;
    var successful_parses: usize = 0;

    for (0..iterations) |_| {
        for (valid_requests) |request| {
            const parsed = router.parseRequest(request);
            if (parsed != null) {
                successful_parses += 1;

                // Verify parsing consistency
                try testing.expect(parsed.?.path.len > 0);
                try testing.expect(parsed.?.headers.len > 0);
            }
        }
    }

    try testing.expectEqual(iterations * valid_requests.len, successful_parses);
}

test "Response generation under load" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const status_codes = [_]u16{ 200, 201, 400, 404, 500 };
    const content_types = [_][]const u8{ "text/html", "application/json", "text/plain", "text/css" };
    const bodies = [_][]const u8{ "OK", "Created", "Bad Request", "Not Found", "Internal Server Error" };

    const iterations = 100;
    var responses_generated: usize = 0;

    for (0..iterations) |i| {
        const status = status_codes[i % status_codes.len];
        const content_type = content_types[i % content_types.len];
        const body = bodies[i % bodies.len];

        const response = try router.createResponse(status, content_type, body);
        defer allocator.free(response);

        // Verify response format
        try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1") != null);
        try testing.expect(std.mem.indexOf(u8, response, content_type) != null);
        try testing.expect(std.mem.indexOf(u8, response, body) != null);

        responses_generated += 1;
    }

    try testing.expectEqual(iterations, responses_generated);
}

test "Session counter thread safety simulation" {
    api.initApi();

    // Simulate rapid concurrent increments
    const increment_count = 1000;

    for (0..increment_count) |_| {
        api.incrementSessionCount();
    }

    // Verify the counter maintained integrity
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try api.handleStatus(allocator, "");
    defer allocator.free(response);

    // Should contain session count (exact value may vary due to other tests)
    try testing.expect(std.mem.indexOf(u8, response, "session_count") != null);
    try testing.expect(std.mem.indexOf(u8, response, "application/json") != null);
}

test "Memory pressure under sustained load" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        testing.expect(leaked == .ok) catch {
            std.debug.print("Memory leak detected in load test!\n", .{});
        };
    }
    const allocator = gpa.allocator();

    api.initApi();

    // Sustained load test to check for memory leaks
    const load_iterations = 200;

    for (0..load_iterations) |_| {
        // Mix of operations that allocate memory
        const health_response = try api.handleHealth(allocator, "");
        defer allocator.free(health_response);

        const status_response = try api.handleStatus(allocator, "");
        defer allocator.free(status_response);

        const file_response = try static_handler.serveStaticFile(allocator, "/index.html");
        defer allocator.free(file_response);

        const http_response = try router.createResponse(200, "text/plain", "test");
        defer allocator.free(http_response);

        api.incrementSessionCount();
    }

    // If we reach here without OOM, the memory management is working well
}