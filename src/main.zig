const std = @import("std");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_impl.interface;

    var args = std.process.args();
    _ = args.next();

    const filename = args.next() orelse {
        try stdout.print("Usage: wc <filename>\n", .{});
        try stdout.flush();
        return;
    };

    // open the file
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        try stdout.print("Error opening file '{s}': {}\n", .{ filename, err });
        try stdout.flush();
        return;
    };
    defer file.close();

    // read the entire file into a buffer
    var read_buffer: [1024 * 1024]u8 = undefined; // 1MB buffer
    const bytes_read = try file.readAll(&read_buffer);
    const contents = read_buffer[0..bytes_read];

    try stdout.print("File: {s}\n", .{filename});
    try stdout.print("Bytes read: {d}\n", .{bytes_read});
    try stdout.print("Contents preview: {s}\n", .{contents[0..@min(50, bytes_read)]});
    try stdout.flush();
}