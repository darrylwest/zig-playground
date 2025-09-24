const std = @import("std");
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

// Generic map function
pub fn map(comptime T: type, comptime U: type, allocator: std.mem.Allocator, slice: []const T, func: fn (T) U) !ArrayList(U) {
    var result = try ArrayList(U).initCapacity(allocator, slice.len);
    for (slice) |item| {
        try result.append(allocator, func(item));
    }
    return result;
}

// Generic filter function
pub fn filter(comptime T: type, allocator: std.mem.Allocator, slice: []const T, predicate: fn (T) bool) !ArrayList(T) {
    var result = try ArrayList(T).initCapacity(allocator, slice.len);
    for (slice) |item| {
        if (predicate(item)) {
            try result.append(allocator, item);
        }
    }
    return result;
}

// Generic reduce function
pub fn reduce(comptime T: type, comptime U: type, slice: []const T, initial: U, func: fn (U, T) U) U {
    var acc = initial;
    for (slice) |item| {
        acc = func(acc, item);
    }
    return acc;
}

// Generic forEach function
pub fn forEach(comptime T: type, slice: []const T, func: fn (T) void) void {
    for (slice) |item| {
        func(item);
    }
}

// Helper functions for demonstrations
fn square(x: i32) i32 {
    return x * x;
}

fn isEven(x: i32) bool {
    return @rem(x, 2) == 0;
}

fn add(acc: i32, x: i32) i32 {
    return acc + x;
}

fn multiply(acc: i32, x: i32) i32 {
    return acc * x;
}

fn printNum(x: i32) void {
    print("{} ", .{x});
}

fn doubleToString(x: i32) []const u8 {
    // In a real implementation, you'd want proper string formatting
    // This is simplified for demonstration
    if (x * 2 == 2) return "2";
    if (x * 2 == 4) return "4";
    if (x * 2 == 6) return "6";
    if (x * 2 == 8) return "8";
    if (x * 2 == 10) return "10";
    return "unknown";
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    print("=== Functional Programming in Zig Demo ===\n\n", .{});

    // Original data
    const numbers = [_]i32{ 1, 2, 3, 4, 5 };
    print("Original numbers: ", .{});
    forEach(i32, &numbers, printNum);
    print("\n\n", .{});

    // Map example: square all numbers
    print("Map (square): ", .{});
    var squared = try map(i32, i32, allocator, &numbers, square);
    defer squared.deinit(allocator);
    forEach(i32, squared.items, printNum);
    print("\n", .{});

    // Filter example: get even numbers only
    print("Filter (even): ", .{});
    var evens = try filter(i32, allocator, &numbers, isEven);
    defer evens.deinit(allocator);
    forEach(i32, evens.items, printNum);
    print("\n", .{});

    // Reduce example: sum all numbers
    const sum = reduce(i32, i32, &numbers, 0, add);
    print("Reduce (sum): {}\n", .{sum});

    // Reduce example: product of all numbers
    const product = reduce(i32, i32, &numbers, 1, multiply);
    print("Reduce (product): {}\n", .{product});

    // Chaining operations example
    print("\nChaining operations:\n", .{});
    print("Original: ", .{});
    forEach(i32, &numbers, printNum);
    print("\n", .{});

    // First filter evens, then square them
    var evenSquared = try map(i32, i32, allocator, evens.items, square);
    defer evenSquared.deinit(allocator);
    print("Even numbers squared: ", .{});
    forEach(i32, evenSquared.items, printNum);
    print("\n", .{});

    // Map to different type (int to string)
    print("Map to strings (double): ", .{});
    var stringResults = try map(i32, []const u8, allocator, &numbers, doubleToString);
    defer stringResults.deinit(allocator);
    for (stringResults.items) |str| {
        print("{s} ", .{str});
    }
    print("\n", .{});
}

// Tests
test "map function" {
    const allocator = testing.allocator;
    const input = [_]i32{ 1, 2, 3, 4 };

    var result = try map(i32, i32, allocator, &input, square);
    defer result.deinit(allocator);

    const expected = [_]i32{ 1, 4, 9, 16 };
    try testing.expectEqualSlices(i32, &expected, result.items);
}

test "filter function" {
    const allocator = testing.allocator;
    const input = [_]i32{ 1, 2, 3, 4, 5, 6 };

    var result = try filter(i32, allocator, &input, isEven);
    defer result.deinit(allocator);

    const expected = [_]i32{ 2, 4, 6 };
    try testing.expectEqualSlices(i32, &expected, result.items);
}

test "reduce function - sum" {
    const input = [_]i32{ 1, 2, 3, 4, 5 };
    const result = reduce(i32, i32, &input, 0, add);
    try testing.expectEqual(@as(i32, 15), result);
}

test "reduce function - product" {
    const input = [_]i32{ 2, 3, 4 };
    const result = reduce(i32, i32, &input, 1, multiply);
    try testing.expectEqual(@as(i32, 24), result);
}

test "empty array handling" {
    const allocator = testing.allocator;
    const input = [_]i32{};

    var mapResult = try map(i32, i32, allocator, &input, square);
    defer mapResult.deinit(allocator);
    try testing.expectEqual(@as(usize, 0), mapResult.items.len);

    var filterResult = try filter(i32, allocator, &input, isEven);
    defer filterResult.deinit(allocator);
    try testing.expectEqual(@as(usize, 0), filterResult.items.len);

    const reduceResult = reduce(i32, i32, &input, 42, add);
    try testing.expectEqual(@as(i32, 42), reduceResult);
}
