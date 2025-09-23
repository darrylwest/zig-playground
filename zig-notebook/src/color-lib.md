# Zig Color Lib

## Overview 

A **zig** library that support **colorizing** the terminal.
It's a simple, efficient ANSI color library for Zig console applications. This library provides easy-to-use functions for adding colors and text formatting to terminal output with intelligent color support detection.

## Features

* Complete ANSI color support, normal and bright colors, text styles
* Smart Color Detection
* Multiple usage patterns with simple functions or direct ANSI codes
* Zero Dependencies
* Easy Integration
* Well Tested

## Installation

You can install the library using `zig fetch ...`, then update your `build.zig and buid.zig.zog` files and you are ready to use.

## Usage

### Direct Ansi Codes

Using raw ANSI escape codes:

```zig
const color = @import("zig-color");

// Print red text
std.debug.print("{s}Error message{s}\n", .{ color.codes.red, color.codes.reset });

// Combine styles
std.debug.print("{s}{s}Bold red warning{s}\n", .{
    color.codes.bold,
    color.codes.red,
    color.codes.reset
});
```

Available codes:

- Colors: `red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `white`, `black`
- Bright colors: `bright_red`, `bright_green`, `bright_blue`, etc.
- Background: `bg_red`, `bg_green`, `bg_blue`, etc.
- Styles: `bold`, `dim`, `italic`, `underline`, `blink`, `reverse`, `strikethrough`
- Reset: `reset` (always use this to return to normal formatting)


### Simple Functions
 
Use the `simple` namespace for functions that always apply colors regardless of terminal support:

```zig
const color = @import("zig-color");

const allocator = std.heap.page_allocator;

// These always return colored text
const red_text = try color.simple.red("Error", allocator);
const green_text = try color.simple.green("Success", allocator);
const blue_text = try color.simple.blue("Info", allocator);
const yellow_text = try color.simple.yellow("Warning", allocator);
const bold_text = try color.simple.bold("Important", allocator);

// Don't forget to free the allocated strings
defer allocator.free(red_text);
defer allocator.free(green_text);
// ... etc
```

### Smart Color Support

The `ColorSupport` struct automatically detects terminal capabilities and environment preferences:

```zig
const color = @import("zig-color");

const color_support = color.ColorSupport.init();

if (color_support.enabled) {
    std.debug.print("Terminal supports colors!\n", .{});
}

// These functions respect the color support detection
const smart_red = try color_support.red("Error", allocator);
const smart_green = try color_support.green("Success", allocator);

// Direct printing methods
try color_support.printRed(writer, "Error: {s}\n", .{"Something failed"});
try color_support.printGreen(writer, "Success: {} items processed\n", .{42});
```

### Example Application


## References

* [github repo](https://github.com/darrylwest/zig-color-lib)

###### dpw | 2025.09.22
