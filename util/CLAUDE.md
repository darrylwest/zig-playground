# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Zig utilities playground project containing educational examples demonstrating basic Zig language features including:

- Basic "Hello World" program (`hello.zig`)
- String literals and Unicode handling (`string_literals.zig`)
- Value types, optionals, and error unions (`values.zig`)

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

## Project Structure

```
/
├── build.zig          # Build configuration for all .zig files
├── hello.zig          # Basic hello world example
├── string_literals.zig # String and Unicode demonstrations
├── values.zig         # Value types, optionals, error unions
└── zig-out/           # Build output directory
    └── bin/           # Compiled executables
```

## Development Notes

- Each .zig file is a standalone program with its own `main()` function
- Files are educational examples showcasing different Zig language features
- No external dependencies or modules are used
- All examples use only the Zig standard library