const std = @import("std");
const testing = std.testing;
const static_handler = @import("../src/handlers/static.zig");

test "Serve existing HTML file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/index.html");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Type: text/html") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Welcome to Zig HTTP Server") != null);
}

test "Serve existing CSS file" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/css/style.css");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Content-Type: text/css") != null);
}

test "Serve non-existent file returns 404" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/nonexistent.html");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 404 Not Found") != null);
    try testing.expect(std.mem.indexOf(u8, response, "404 Not Found") != null);
}

test "MIME type detection for HTML" {
    // We can't directly test the private getMimeType function, but we can test it through serveStaticFile
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/about.html");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "Content-Type: text/html") != null);
}

test "MIME type detection for CSS" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/css/style.css");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "Content-Type: text/css") != null);
}

test "Serve about page" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/about.html");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "About Zig HTTP Server") != null);
}

test "Serve contact page" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/contact.html");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "Contact Us") != null);
}

test "Serve API reference page" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const response = try static_handler.serveStaticFile(allocator, "/api-reference.html");
    defer allocator.free(response);

    try testing.expect(std.mem.indexOf(u8, response, "HTTP/1.1 200 OK") != null);
    try testing.expect(std.mem.indexOf(u8, response, "API Reference") != null);
}