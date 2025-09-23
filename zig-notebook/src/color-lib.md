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

### Simple Functions
 

### Smart Color Support


### Example Application


## References

* [github repo](https://github.com/darrylwest/zig-color-lib)

###### dpw | 2025.09.22
