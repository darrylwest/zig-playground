const std = @import("std");
const testing = std.testing;
const api = @import("../src/handlers/api.zig");
const static_handler = @import("../src/handlers/static.zig");
const router = @import("../src/router.zig");

// Performance test thresholds (in nanoseconds)
const FAST_THRESHOLD = 1_000_000; // 1ms
const ACCEPTABLE_THRESHOLD = 10_000_000; // 10ms

fn benchmarkFunction(comptime func: anytype, args: anytype) !u64 {
    const start = std.time.nanoTimestamp();
    _ = try @call(.auto, func, args);
    const end = std.time.nanoTimestamp();
    return @as(u64, @intCast(end - start));
}

fn benchmarkFunctionWithCleanup(comptime func: anytype, args: anytype, allocator: std.mem.Allocator) !u64 {
    const start = std.time.nanoTimestamp();
    const result = try @call(.auto, func, args);
    defer allocator.free(result);
    const end = std.time.nanoTimestamp();
    return @as(u64, @intCast(end - start));
}

test "API endpoint response time benchmarks" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    api.initApi();

    const request = "GET /api/v1/health HTTP/1.1\r\nHost: localhost\r\n\r\n";

    // Benchmark health endpoint
    const health_time = try benchmarkFunctionWithCleanup(api.handleHealth, .{ allocator, request }, allocator);
    std.debug.print("Health endpoint: {}ns ({}μs)\n", .{ health_time, health_time / 1000 });
    try testing.expect(health_time < ACCEPTABLE_THRESHOLD);

    // Benchmark ping endpoint
    const ping_time = try benchmarkFunctionWithCleanup(api.handlePing, .{ allocator, request }, allocator);
    std.debug.print("Ping endpoint: {}ns ({}μs)\n", .{ ping_time, ping_time / 1000 });
    try testing.expect(ping_time < ACCEPTABLE_THRESHOLD);

    // Benchmark version endpoint
    const version_time = try benchmarkFunctionWithCleanup(api.handleVersion, .{ allocator, request }, allocator);
    std.debug.print("Version endpoint: {}ns ({}μs)\n", .{ version_time, version_time / 1000 });
    try testing.expect(version_time < ACCEPTABLE_THRESHOLD);

    // Benchmark status endpoint (more complex due to JSON generation)
    const status_time = try benchmarkFunctionWithCleanup(api.handleStatus, .{ allocator, request }, allocator);
    std.debug.print("Status endpoint: {}ns ({}μs)\n", .{ status_time, status_time / 1000 });
    try testing.expect(status_time < ACCEPTABLE_THRESHOLD * 2); // Allow more time for JSON generation
}

test "Static file serving performance" {
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

    for (files) |file_path| {
        const serve_time = try benchmarkFunctionWithCleanup(static_handler.serveStaticFile, .{ allocator, file_path }, allocator);
        std.debug.print("Serving {s}: {}ns ({}μs)\n", .{ file_path, serve_time, serve_time / 1000 });

        // File serving should be fast, but allow more time for disk I/O
        try testing.expect(serve_time < ACCEPTABLE_THRESHOLD * 5);
    }
}

test "Request parsing performance" {
    const requests = [_][]const u8{
        "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n",
        "POST /api/data HTTP/1.1\r\nContent-Type: application/json\r\nContent-Length: 100\r\n\r\n",
        "PUT /api/users/123 HTTP/1.1\r\nAuthorization: Bearer token123\r\nAccept: application/json\r\n\r\n",
        "DELETE /api/items/456 HTTP/1.1\r\nUser-Agent: TestClient/1.0\r\nAccept-Language: en-US,en;q=0.9\r\n\r\n",
    };

    for (requests) |request| {
        const parse_time = try benchmarkFunction(router.parseRequest, .{request});
        std.debug.print("Parsing request: {}ns ({}μs)\n", .{ parse_time, parse_time / 1000 });

        // Request parsing should be very fast
        try testing.expect(parse_time < FAST_THRESHOLD);
    }
}

test "Response generation performance" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = std.heap.page_allocator; // Use page allocator for benchmarking

    const test_cases = [_]struct {
        status: u16,
        content_type: []const u8,
        body: []const u8,
    }{
        .{ .status = 200, .content_type = "text/plain", .body = "OK" },
        .{ .status = 404, .content_type = "text/html", .body = "<html><body><h1>Not Found</h1></body></html>" },
        .{ .status = 200, .content_type = "application/json", .body = "{\"message\":\"success\",\"data\":[1,2,3,4,5]}" },
    };

    for (test_cases) |case| {
        const response_time = try benchmarkFunctionWithCleanup(router.createResponse, .{ case.status, case.content_type, case.body }, allocator);
        std.debug.print("Response generation ({}): {}ns ({}μs)\n", .{ case.status, response_time, response_time / 1000 });

        // Response generation should be fast
        try testing.expect(response_time < ACCEPTABLE_THRESHOLD);
    }
}

test "Session increment performance" {
    api.initApi();

    const iterations = 1000;
    const start = std.time.nanoTimestamp();

    for (0..iterations) |_| {
        api.incrementSessionCount();
    }

    const end = std.time.nanoTimestamp();
    const total_time = @as(u64, @intCast(end - start));
    const avg_time = total_time / iterations;

    std.debug.print("Session increment {} times: {}ns total, {}ns avg\n", .{ iterations, total_time, avg_time });

    // Session increments should be extremely fast
    try testing.expect(avg_time < 1000); // Less than 1μs per increment
}

test "End-to-end request processing performance" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    api.initApi();

    const request = "GET /api/v1/status HTTP/1.1\r\nHost: localhost:8080\r\nUser-Agent: BenchmarkClient\r\n\r\n";

    const start = std.time.nanoTimestamp();

    // Simulate full request processing pipeline
    const parsed = router.parseRequest(request);
    try testing.expect(parsed != null);

    api.incrementSessionCount();

    const response = try api.handleStatus(allocator, request);
    defer allocator.free(response);

    const end = std.time.nanoTimestamp();
    const total_time = @as(u64, @intCast(end - start));

    std.debug.print("End-to-end processing: {}ns ({}μs)\n", .{ total_time, total_time / 1000 });

    // Full pipeline should complete within reasonable time
    try testing.expect(total_time < ACCEPTABLE_THRESHOLD * 3);
    try testing.expect(std.mem.indexOf(u8, response, "application/json") != null);
}

test "Performance consistency over multiple runs" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    api.initApi();

    const runs = 50;
    var times = try allocator.alloc(u64, runs);
    defer allocator.free(times);

    // Measure multiple runs
    for (0..runs) |i| {
        times[i] = try benchmarkFunctionWithCleanup(api.handleHealth, .{ allocator, "" }, allocator);
    }

    // Calculate statistics
    var sum: u64 = 0;
    var min_time: u64 = std.math.maxInt(u64);
    var max_time: u64 = 0;

    for (times) |time| {
        sum += time;
        min_time = @min(min_time, time);
        max_time = @max(max_time, time);
    }

    const avg_time = sum / runs;
    const time_variance = max_time - min_time;

    std.debug.print("Performance over {} runs:\n", .{runs});
    std.debug.print("  Average: {}ns ({}μs)\n", .{ avg_time, avg_time / 1000 });
    std.debug.print("  Min: {}ns ({}μs)\n", .{ min_time, min_time / 1000 });
    std.debug.print("  Max: {}ns ({}μs)\n", .{ max_time, max_time / 1000 });
    std.debug.print("  Variance: {}ns ({}μs)\n", .{ time_variance, time_variance / 1000 });

    // Performance should be consistent (variance shouldn't be too high)
    try testing.expect(avg_time < ACCEPTABLE_THRESHOLD);
    try testing.expect(time_variance < ACCEPTABLE_THRESHOLD * 10); // Max variance of 100ms
}

test "Memory allocation performance" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    api.initApi();

    const iterations = 100;
    const start = std.time.nanoTimestamp();

    for (0..iterations) |_| {
        const response = try api.handleStatus(allocator, "");
        defer allocator.free(response);
        // Each iteration allocates and frees memory
    }

    const end = std.time.nanoTimestamp();
    const total_time = @as(u64, @intCast(end - start));
    const avg_time = total_time / iterations;

    std.debug.print("Memory alloc/free {} times: {}ns total, {}ns avg\n", .{ iterations, total_time, avg_time });

    // Memory operations should be reasonable
    try testing.expect(avg_time < ACCEPTABLE_THRESHOLD * 2);
}