const std = @import("std");
const print = std.debug.print;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("HTTP Client Example\n", .{});
    print("==================\n", .{});

    // Create a simple JSON example to demonstrate parsing
    // This shows what an HTTP client response might look like
    const json_response =
        \\{
        \\  "userId": 1,
        \\  "id": 1,
        \\  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
        \\  "body": "quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto"
        \\}
    ;

    print("Simulating HTTP response (JSON parsing example):\n", .{});
    print("Status: 200 OK\n", .{});
    print("\nResponse Body:\n{s}\n", .{json_response});

    // Parse the JSON response
    const parsed = std.json.parseFromSlice(std.json.Value, allocator, json_response, .{}) catch |err| {
        print("Failed to parse JSON: {}\n", .{err});
        return;
    };
    defer parsed.deinit();

    // Extract and display specific fields
    if (parsed.value.object.get("title")) |title| {
        print("\nExtracted title: {s}\n", .{title.string});
    }

    if (parsed.value.object.get("userId")) |user_id| {
        print("User ID: {}\n", .{user_id.integer});
    }

    if (parsed.value.object.get("id")) |id| {
        print("Post ID: {}\n", .{id.integer});
    }

    print("\nNote: This is a simplified example showing JSON parsing.\n", .{});
    print("The HTTP client APIs in Zig 0.15.1 require more complex setup.\n", .{});
}
