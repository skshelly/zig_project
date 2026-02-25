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

    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        try stdout.print("Error opening file '{s}': {}\n", .{ filename, err });
        try stdout.flush();
        return;
    };
    defer file.close();

    var read_buffer: [1024 * 1024]u8 = undefined;
    const bytes_read = try file.readAll(&read_buffer);
    const contents = read_buffer[0..bytes_read];

    // count lines, words, characters
    var lines: usize = 0;
    var words: usize = 0;
    const chars: usize = contents.len;
    var in_word = false;

    for (contents) |c| {
        if (c == '\n') lines += 1;
        if (c == ' ' or c == '\n' or c == '\t') {
            in_word = false;
        } else if (!in_word) {
            in_word = true;
            words += 1;
        }
    }

    try stdout.print("\nResults for: {s}\n", .{filename});
    try stdout.print("  Lines:      {d}\n", .{lines});
    try stdout.print("  Words:      {d}\n", .{words});
    try stdout.print("  Characters: {d}\n", .{chars});
    try stdout.flush();
}