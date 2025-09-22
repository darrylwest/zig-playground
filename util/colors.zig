const std = @import("std");
const builtin = @import("builtin");

pub const ColorSupport = struct {
    enabled: bool,
    
    pub fn init() ColorSupport {
        return ColorSupport{
            .enabled = detectColorSupport(),
        };
    }
    
    fn detectColorSupport() bool {
        // Check if we're on a TTY
        if (!std.io.getStdOut().isTty()) {
            return false;
        }
        
        // Check environment variables
        if (std.os.getenv("NO_COLOR")) |_| {
            return false;
        }
        
        if (std.os.getenv("FORCE_COLOR")) |_| {
            return true;
        }
        
        if (std.os.getenv("TERM")) |term| {
            if (std.mem.eql(u8, term, "dumb")) {
                return false;
            }
        }
        
        // On Windows, check for newer terminal support
        if (builtin.os.tag == .windows) {
            // Windows 10 version 1607 and later support ANSI
            // This is a simplified check
            return true;
        }
        
        return true;
    }
    
    pub fn colorize(self: *const ColorSupport, color: []const u8, text: []const u8, allocator: std.mem.Allocator) ![]u8 {
        if (self.enabled) {
            return try std.fmt.allocPrint(allocator, "{s}{s}\x1b[0m", .{ color, text });
        } else {
            return try allocator.dupe(u8, text);
        }
    }
    
    pub fn red(self: *const ColorSupport, text: []const u8, allocator: std.mem.Allocator) ![]u8 {
        return self.colorize("\x1b[31m", text, allocator);
    }
    
    pub fn green(self: *const ColorSupport, text: []const u8, allocator: std.mem.Allocator) ![]u8 {
        return self.colorize("\x1b[32m", text, allocator);
    }
    
    pub fn blue(self: *const ColorSupport, text: []const u8, allocator: std.mem.Allocator) ![]u8 {
        return self.colorize("\x1b[34m", text, allocator);
    }
    
    pub fn yellow(self: *const ColorSupport, text: []const u8, allocator: std.mem.Allocator) ![]u8 {
        return self.colorize("\x1b[33m", text, allocator);
    }
    
    pub fn bold(self: *const ColorSupport, text: []const u8, allocator: std.mem.Allocator) ![]u8 {
        return self.colorize("\x1b[1m", text, allocator);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    const color_support = ColorSupport.init();
    const stdout = std.io.getStdOut().writer();
    
    if (color_support.enabled) {
        try stdout.print("Color support is enabled!\n", .{});
    } else {
        try stdout.print("Color support is disabled.\n", .{});
    }
    
    const red_text = try color_support.red("This might be red!", allocator);
    defer allocator.free(red_text);
    try stdout.print("{s}\n", .{red_text});
    
    const green_text = try color_support.green("This might be green!", allocator);
    defer allocator.free(green_text);
    try stdout.print("{s}\n", .{green_text});
}
