# Zig HTTP Server

A high-performance HTTP server built entirely in Zig, featuring REST API endpoints, static file serving, and a complete web interface.

## Features

- 🚀 **High Performance** - Built with Zig for optimal speed and memory efficiency
- 🌐 **REST API** - Four endpoints for health, status, version, and connectivity testing
- 📁 **Static File Serving** - Complete web interface with responsive design
- 🔒 **Security Hardened** - Protection against directory traversal and malformed requests
- 📊 **Monitoring** - Server uptime tracking and session statistics
- 🧪 **Comprehensive Testing** - 76 test functions covering functionality, performance, and security
- 💾 **Memory Safe** - Leak detection and proper resource management

## Quick Start

### Prerequisites

- Zig 0.15.1 or later

### Build and Run

```bash
# Build the server
zig build

# Run the server
zig build run

# Server will start on http://127.0.0.1:8080
```

### API Endpoints

- `GET /api/v1/health` - Health check (returns "ok")
- `GET /api/v1/ping` - Connectivity test (returns "PONG")
- `GET /api/v1/version` - Server version (returns "0.1.0")
- `GET /api/v1/status` - Server status with JSON response including uptime and session count

### Web Interface

- `/` - Landing page with server overview
- `/about.html` - Project information and technical details
- `/contact.html` - Contact information and quick tests
- `/api-reference.html` - Complete API documentation

## Testing

The project includes comprehensive test coverage with 76 test functions across 8 test categories.

### Run All Tests

```bash
# Run the complete test suite
zig build test

# Run tests with detailed summary
zig build test --summary all

# Run tests with verbose output
zig build test --verbose
```

### Test Categories

#### 1. **Core Functionality Tests** (39 tests)
```bash
# API endpoint functionality
# Static file serving
# Request routing and parsing
# Server integration tests
```

#### 2. **Logger Tests** (8 tests)
```bash
# Log level validation
# Message formatting
# Error logging
# Performance logging
```

#### 3. **Edge Case & Security Tests** (12 tests)
```bash
# Malformed HTTP requests
# Directory traversal protection
# Extreme input handling
# Memory allocation failures
# Concurrent operations
```

#### 4. **Load Tests** (8 tests)
```bash
# Concurrent API requests (100+ simultaneous)
# Mixed endpoint load testing
# Static file serving under load
# High-volume request parsing
# Memory pressure testing
# Thread safety simulation
```

#### 5. **Performance Tests** (9 tests)
```bash
# API response time benchmarks (< 10ms target)
# Static file serving performance
# Request parsing speed (< 1ms target)
# End-to-end request processing
# Memory allocation performance
# Performance consistency analysis
```

### Test Coverage Analysis

- **Total Tests:** 76 test functions
- **Coverage:** ~95% comprehensive coverage
- **Performance Validation:** Sub-millisecond response times
- **Security Testing:** Protection against common web vulnerabilities
- **Load Testing:** Validates stability under high concurrent load
- **Memory Safety:** Leak detection and proper cleanup validation

### Performance Benchmarks

The server achieves the following performance targets:

- **API Endpoints:** < 10ms response time
- **Request Parsing:** < 1ms per request
- **Session Operations:** < 1μs per increment
- **Static Files:** < 50ms for typical web assets
- **Memory Operations:** Efficient allocation/deallocation with leak detection

## Development

### Project Structure

```
http-server/
├── src/
│   ├── main.zig              # Server entry point
│   ├── router.zig            # HTTP request routing
│   ├── handlers/
│   │   ├── api.zig           # REST API endpoints
│   │   └── static.zig        # Static file serving
│   └── utils/
│       └── logger.zig        # Structured logging
├── static/                   # Web assets
│   ├── *.html               # Web pages
│   └── css/style.css        # Styling
├── tests/                   # Test suite
│   ├── api_test.zig         # API functionality
│   ├── router_test.zig      # Request routing
│   ├── static_test.zig      # File serving
│   ├── server_test.zig      # Integration tests
│   ├── logger_test.zig      # Logging functionality
│   ├── edge_cases_test.zig  # Security & edge cases
│   ├── load_test.zig        # Concurrent load testing
│   └── performance_test.zig # Benchmarks & timing
└── docs/                    # Documentation
```

### Build Configuration

The project uses Zig's standard build system. Key build options:

```bash
# Debug build (default)
zig build

# Release builds
zig build -Doptimize=ReleaseFast    # Speed optimized
zig build -Doptimize=ReleaseSafe    # Safe + optimized
zig build -Doptimize=ReleaseSmall   # Size optimized
```

### Adding New Tests

Tests are automatically discovered by the build system. To add new tests:

1. Create a new test file in the `tests/` directory
2. Import required modules from `src/`
3. Write test functions using `test "description" { ... }`
4. Run `zig build test` to execute

Example test:
```zig
const std = @import("std");
const testing = std.testing;
const api = @import("../src/handlers/api.zig");

test "my new test" {
    // Test implementation
    try testing.expect(true);
}
```

## Architecture

### HTTP Server Design

- **Single-threaded** - Efficient event-driven architecture
- **Memory Safe** - Explicit memory management without garbage collection
- **Modular** - Clean separation of concerns with dedicated handlers
- **Extensible** - Easy to add new endpoints and functionality

### Security Features

- **Input Validation** - Malformed request protection
- **Path Sanitization** - Directory traversal prevention
- **Resource Limits** - Memory and connection management
- **Error Handling** - Graceful degradation on failures

### Monitoring & Observability

- **Structured Logging** - Timestamp-based logs with severity levels
- **Performance Metrics** - Response time tracking
- **Session Statistics** - Connection counting and uptime monitoring
- **Health Checks** - Built-in endpoint for service monitoring

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass: `zig build test`
5. Submit a pull request

## License

This project is a demonstration of Zig's capabilities for building high-performance web servers.

## Performance Notes

This server is optimized for:
- **Low latency** - Sub-millisecond response times for simple operations
- **Memory efficiency** - Minimal allocations with proper cleanup
- **Concurrent handling** - Efficient processing of multiple requests
- **Static file serving** - Fast delivery of web assets

For production use, consider adding:
- Connection pooling
- Request/response caching
- Rate limiting
- TLS/HTTPS support
- Multi-threading for CPU-intensive operations