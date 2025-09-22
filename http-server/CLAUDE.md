# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Zig HTTP server project that aims to build a complete web server using Zig's `std.http` library. The project is currently in the planning/initialization phase and will include:

- Static page serving with HTML/CSS
- REST API endpoints for health, ping, status, and version
- JSON encoding/decoding capabilities
- Unit testing with std.testing framework

## Development Setup

### Zig Version

- Project uses Zig 0.15.1
- Verify version with: `zig version`

### Project Initialization

The project hasn't been initialized yet. To start development:
```bash
zig init
```

### Build Commands

Once initialized, standard Zig commands will be:
```bash
# Build the project
zig build

# Run the application
zig build run

# Run tests
zig build test

# Build in debug mode (default)
zig build -Doptimize=Debug

# Build optimized release
zig build -Doptimize=ReleaseFast
```

## Project Architecture

### Required REST Endpoints

- `/api/v1/health` - returns "ok"
- `/api/v1/ping` - returns "PONG"
- `/api/v1/status` - returns JSON with uptime, session_count, timestamp
- `/api/v1/version` - returns application version (major.minor.patch)

### Static Pages Structure

- Landing page with header, body, footer sections
- Navigation to About, Contact Us, API Reference pages
- Minimal CSS styling

### Core Components

- HTTP server using `std.http`
- Static file serving
- JSON response handling
- Route matching for REST endpoints
- Session/uptime tracking

## Testing Strategy

Use Zig's built-in `std.testing` framework for unit tests. Test coverage should include:

- API endpoint responses
- JSON serialization/deserialization
- Static file serving
- Route matching logic

## Development Notes

- Follow the task sequence outlined in docs/http-server-project.md
- Start with basic server setup and static page serving
- Incrementally add REST endpoints
- Implement JSON handling last
- Add comprehensive tests throughout development
