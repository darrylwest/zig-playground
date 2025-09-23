# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Zig utilities playground project containing educational examples demonstrating Zig language features including:

- Basic "Hello World" program (`hello.zig`)
- String literals and Unicode handling (`string_literals.zig`)
- Value types, optionals, and error unions (`values.zig`)
- Terminal color support utilities (`colors.zig`)
- HTTP client example with JSON parsing (`client.zig`)

## Build System

**Zig Version**: 0.15.1

### Build Commands

- `zig build` - Automatically discovers and compiles all .zig files, placing executables in `zig-out/bin/`
- `zig run <filename>.zig` - Compile and run a single Zig file directly

### Build Configuration

The `build.zig` script automatically:
- Scans the current directory for all .zig files (excluding build.zig)
- Creates individual executables for each discovered file
- Installs them to `zig-out/bin/` with the base filename as the executable name

No manual file list maintenance required - simply add new .zig files to the directory and run `zig build`.

## Dependencies

This project uses one external dependency:
- `zig-color` (v0.2.1) - Color library for terminal output

Dependencies are managed through `build.zig.zon` and automatically fetched during build.

## Project Structure

```
/
├── build.zig          # Build configuration for all .zig files
├── build.zig.zon      # Package dependencies
├── hello.zig          # Basic hello world example
├── string_literals.zig # String and Unicode demonstrations
├── values.zig         # Value types, optionals, error unions
├── colors.zig         # Terminal color utilities
├── client.zig         # HTTP client with JSON parsing
└── zig-out/           # Build output directory
    └── bin/           # Compiled executables
```

## Development Notes

- Each .zig file is a standalone program with its own `main()` function
- Files are educational examples showcasing different Zig language features
- Most examples use only the Zig standard library, with `colors.zig` demonstrating custom color utilities
- `client.zig` demonstrates HTTP requests and JSON parsing using std.http and std.json