// Solution for using response_writer with std.http.Client.fetch() in Zig 0.15.1
// This example demonstrates the correct way to handle HTTP response bodies
// using the new std.Io.Writer interface introduced in Zig 0.15.1

const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create HTTP client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse("https://httpbin.org/json");
    print("Demonstrating HTTP response_writer usage in Zig 0.15.1\n", .{});

    // SOLUTION 1: Using std.Io.Writer.Allocating (recommended)
    // This is the proper replacement for ArrayList writer in Zig 0.15.1
    print("\n--- Solution 1: std.Io.Writer.Allocating ---\n", .{});

    var allocating_writer = std.Io.Writer.Allocating.init(allocator);
    defer allocating_writer.deinit();

    const result1 = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .response_writer = &allocating_writer.writer,
    });

    print("Status: {}\n", .{result1.status});
    const response_data = allocating_writer.written();
    print("Response captured: {} bytes\n", .{response_data.len});

    // You can now use response_data as a []u8 slice
    if (response_data.len > 100) {
        print("First 100 chars: {s}\n", .{response_data[0..100]});
    }

    // SOLUTION 2: Using Fixed Buffer Writer (for known-size responses)
    print("\n--- Solution 2: Fixed Buffer Writer ---\n", .{});

    var fixed_buffer: [4096]u8 = undefined;
    var fixed_writer = std.Io.Writer.fixed(&fixed_buffer);

    const result2 = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .response_writer = &fixed_writer,
    });

    print("Status: {}\n", .{result2.status});
    print("Fixed buffer method completed\n", .{});

    // Important Notes:
    // 1. In Zig 0.15.1, std.ArrayList(u8).writer() returns Io.DeprecatedWriter
    // 2. std.http.Client.fetch expects Io.Writer (not DeprecatedWriter)
    // 3. Use std.Io.Writer.Allocating for dynamic response capture
    // 4. Use std.Io.Writer.fixed() for bounded response capture
}

// Key Changes in Zig 0.15.1:
// - ArrayList no longer stores allocator internally
// - std.io.Writer is deprecated in favor of std.Io.Writer
// - New Io interface requires explicit buffer management
// - response_writer field expects *std.Io.Writer, not the deprecated writer types