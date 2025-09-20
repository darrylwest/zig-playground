const std = @import("std");

var server_start_time: i64 = 0;
var session_count: u32 = 0;

pub fn initApi() void {
    server_start_time = std.time.timestamp();
}

pub fn handleHealth(allocator: std.mem.Allocator, request: []const u8) ![]const u8 {
    _ = request;
    return try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nok", .{}
    );
}

pub fn handlePing(allocator: std.mem.Allocator, request: []const u8) ![]const u8 {
    _ = request;
    return try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 4\r\n\r\nPONG", .{}
    );
}

pub fn parseVersionFromZon(allocator: std.mem.Allocator) ![]const u8 {
    const file = std.fs.cwd().openFile("build.zig.zon", .{}) catch |err| switch (err) {
        error.FileNotFound => return allocator.dupe(u8, "0.0.0"),
        else => return err,
    };
    defer file.close();

    const file_size = try file.getEndPos();
    const contents = try allocator.alloc(u8, file_size);
    defer allocator.free(contents);
    _ = try file.readAll(contents);

    // Look for .version = "x.y.z" pattern
    if (std.mem.indexOf(u8, contents, ".version = \"")) |start_pos| {
        const version_start = start_pos + ".version = \"".len;
        if (std.mem.indexOf(u8, contents[version_start..], "\"")) |end_offset| {
            const version_end = version_start + end_offset;
            const version = contents[version_start..version_end];
            return allocator.dupe(u8, version);
        }
    }

    return allocator.dupe(u8, "0.0.0");
}

pub fn handleVersion(allocator: std.mem.Allocator, request: []const u8) ![]const u8 {
    _ = request;
    const version = parseVersionFromZon(allocator) catch "0.0.0";
    defer allocator.free(version);

    return try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {}\r\n\r\n{s}",
        .{ version.len, version }
    );
}

pub fn handleStatus(allocator: std.mem.Allocator, request: []const u8) ![]const u8 {
    _ = request;

    const current_time = std.time.timestamp();
    const uptime = current_time - server_start_time;

    // Create ISO8601 timestamp
    const epoch_seconds = @as(u64, @intCast(current_time));
    const datetime = std.time.epoch.EpochSeconds{ .secs = epoch_seconds };
    const day_seconds = datetime.getDaySeconds();
    const epoch_day = datetime.getEpochDay();
    const year_day = epoch_day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();

    const timestamp = try std.fmt.allocPrint(allocator,
        "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}Z",
        .{ year_day.year, month_day.month.numeric(), month_day.day_index + 1,
           day_seconds.getHoursIntoDay(), day_seconds.getMinutesIntoHour(), day_seconds.getSecondsIntoMinute() }
    );
    defer allocator.free(timestamp);

    const json_body = try std.fmt.allocPrint(allocator,
        "{{\"uptime\":\"{}\",\"session_count\":{},\"timestamp\":\"{s}\"}}",
        .{ uptime, session_count, timestamp }
    );
    defer allocator.free(json_body);

    return try std.fmt.allocPrint(allocator,
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{s}",
        .{ json_body.len, json_body }
    );
}

pub fn incrementSessionCount() void {
    session_count += 1;
}