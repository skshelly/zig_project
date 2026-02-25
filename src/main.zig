const std = @import("std");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_impl.interface;

    // get the arguments
    var args = std.process.args();
    _ = args.next(); // skip the program name itself

    const filename = args.next() orelse {
        try stdout.print("Usage: wc <filename>\n", .{});
        try stdout.flush();
        return;
    };

    try stdout.print("File: {s}\n", .{filename});
    try stdout.flush();
}