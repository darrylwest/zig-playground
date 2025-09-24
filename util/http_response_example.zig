const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("HTTP Response Writer Example - Zig 0.15.1\n", .{});
    print("==========================================\n", .{});

    // Create HTTP client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Parse the URL
    const uri = try std.Uri.parse("https://httpbin.org/json");
    print("Making request to: https://httpbin.org/json\n", .{});

    // Method 1: Using std.Io.Writer.Allocating (recommended for Zig 0.15.1)
    print("\n--- Method 1: std.Io.Writer.Allocating ---\n", .{});
    var allocating_writer = std.Io.Writer.Allocating.init(allocator);
    defer allocating_writer.deinit();

    // Use fetch with response_writer
    const result1 = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .response_writer = &allocating_writer.writer,
    });

    print("Status: {}\n", .{result1.status});
    const response_data = allocating_writer.written();
    print("Response body length: {} bytes\n", .{response_data.len});

    if (response_data.len > 0) {
        // Show first 200 characters of response
        const preview_len = @min(200, response_data.len);
        print("Response preview: {s}...\n", .{response_data[0..preview_len]});
    }

    // Parse JSON response
    if (response_data.len > 0) {
        const parsed = std.json.parseFromSlice(std.json.Value, allocator, response_data, .{}) catch |err| {
            print("Failed to parse JSON: {}\n", .{err});
            return;
        };
        defer parsed.deinit();

        print("\nParsed JSON structure successfully!\n", .{});
    }

    // Method 2: Using Fixed Buffer with std.Io.Writer
    print("\n--- Method 2: Fixed Buffer Writer ---\n", .{});

    var fixed_buffer: [8192]u8 = undefined;
    var fixed_writer = std.Io.Writer.fixed(&fixed_buffer);

    const result2 = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .response_writer = &fixed_writer,
    });

    print("Status: {}\n", .{result2.status});
    // Note: With fixed buffer, we need to track how much was written
    // This is a simplified example - in practice you'd need to track the write position
    print("Using fixed buffer for response capture\n", .{});
}