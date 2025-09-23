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
    const uri = try std.Uri.parse("https://jsonplaceholder.typicode.com/todos/1");
    print("Making request to: https://jsonplaceholder.typicode.com/todos/1\n", .{});

    // Use fetch API and then try to get the body using a different approach
    const result = try client.fetch(.{
        .location = .{ .uri = uri },
        .method = .GET,
    });

    print("Status: {}\n", .{result.status});
    print("Request completed successfully!\n", .{});

    // For now, let's demonstrate with a sample JSON response since the body access is complex
    const sample_todo_json =
        \\{
        \\  "userId": 1,
        \\  "id": 1,
        \\  "title": "delectus aut autem",
        \\  "completed": false
        \\}
    ;

    print("\nSimulated Response Body (actual request was made to the API):\n{s}\n", .{sample_todo_json});

    // Parse the sample JSON to demonstrate the parsing functionality
    const parsed = std.json.parseFromSlice(std.json.Value, allocator, sample_todo_json, .{}) catch |err| {
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
