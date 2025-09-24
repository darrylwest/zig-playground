# Functional Programming

## Map/Filter/Reduce

**Main Features**:

Complete functional utilities: map, filter, reduce, and forEach
Type-generic implementations: Works with any types that satisfy the constraints
Memory management: Proper allocation/deallocation using Zig's allocator system
Comprehensive examples: Demonstrates various use cases and chaining operations

**Main Function Demonstrations**:

Basic map operation (squaring numbers)
Filter operation (getting even numbers)
Reduce operations (sum and product)
Chaining operations (filter then map)
Cross-type mapping (integers to strings)

```zig
// Generic map function
pub fn map(
        comptime T: type, 
        comptime U: type, 
        allocator: std.mem.Allocator, 
        slice: []const T, 
        func: fn (T) U) 
    !ArrayList(U) {
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
```

**Main**

```zig
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
```

**Test Suite**:

Tests for each functional operation
Edge case testing (empty arrays)
Memory safety verification
Type conversion testing

**Key Zig Concepts Demonstrated**:

* Comptime generics: Functions work with any compatible types
* Memory management: Explicit allocator usage
* Error handling: Functions that can fail use ! return types
* Testing framework: Built-in test support with zig test
* Slices vs Arrays: Proper handling of both fixed arrays and dynamic slices

The implementation shows how Zig's systems programming approach requires more explicit memory management than higher-level functional languages, but still allows for clean functional programming patterns.

## Community Libraries

There are several community projects that provide functional programming utilities:

* zig-fp - A functional programming library with common FP operations
* zap - Includes some functional utilities alongside web framework features
* zig-algorithms - Contains various algorithmic implementations including functional-style operations

Zig's Approach
Zig tends to favor explicit, low-level control over high-level abstractions. The language philosophy emphasizes:

No hidden memory allocations
Explicit error handling
Compile-time evaluation where possible
Minimal runtime overhead

This means functional programming patterns are possible but require more explicit memory management compared to garbage-collected languages.
Comptime Features
Zig's comptime feature enables some functional-style metaprogramming at compile time, which can be used to generate efficient code with functional patterns.
Would you like me to show you a complete example of how to implement and use these functional operations in Zig?

###### dpw | 2025.09.23