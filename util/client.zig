const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("HTTP Client Example\n", .{});
    print("==================\n", .{});

    // Create HTTP client
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // Parse the URL
    const uri = try std.Uri.parse("https://jsonplaceholder.typicode.com/todos/3");
    print("Making request to: https://jsonplaceholder.typicode.com/todos/1\n", .{});

    // Using std.Io.Writer.Allocating to capture the response body in Zig 0.15.1
    var response_writer = std.Io.Writer.Allocating.init(allocator);
    defer response_writer.deinit();

    const result = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
        .response_writer = &response_writer.writer,
    });

    print("Status: {}\n", .{result.status});
    print("Request completed successfully!\n", .{});

    // Get the actual response body from the writer
    const response_body = response_writer.written();
    print("\nResponse Body ({} bytes):\n{s}\n", .{ response_body.len, response_body });

    // Parse the JSON response
    const parsed = std.json.parseFromSlice(std.json.Value, allocator, response_body, .{}) catch |err| {
        print("Failed to parse JSON: {}\n", .{err});
        return;
    };
    defer parsed.deinit();

    // Extract and display specific fields for a todo item
    if (parsed.value.object.get("title")) |title| {
        print("\nTodo title: {s}\n", .{title.string});
    }

    if (parsed.value.object.get("userId")) |user_id| {
        print("User ID: {}\n", .{user_id.integer});
    }

    if (parsed.value.object.get("id")) |id| {
        print("Todo ID: {}\n", .{id.integer});
    }

    if (parsed.value.object.get("completed")) |completed| {
        print("Completed: {}\n", .{completed.bool});
    }
}
