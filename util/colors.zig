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
        // Check environment variables first
        if (std.posix.getenv("NO_COLOR")) |_| {
            return false;
        }

        if (std.posix.getenv("FORCE_COLOR")) |_| {
            return true;
        }

        if (std.posix.getenv("TERM")) |term| {
            if (std.mem.eql(u8, term, "dumb")) {
                return false;
            }
        }

        // On Windows, assume color support
        if (builtin.os.tag == .windows) {
            return true;
        }

        // For Unix-like systems, assume color support if TERM is set
        if (std.posix.getenv("TERM")) |_| {
            return true;
        }

        return false;
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

    if (color_support.enabled) {
        std.debug.print("Color support is enabled!\n", .{});
    } else {
        std.debug.print("Color support is disabled.\n", .{});
    }

    const red_text = try color_support.red("This might be red!", allocator);
    defer allocator.free(red_text);
    std.debug.print("{s}\n", .{red_text});

    const green_text = try color_support.green("This might be green!", allocator);
    defer allocator.free(green_text);
    std.debug.print("{s}\n", .{green_text});
}
