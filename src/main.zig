const std = @import("std");

pub fn main() !void {
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_impl.interface;
    try stdout.print("Word Counter\n", .{});
    try stdout.flush();
}