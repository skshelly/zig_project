const std = @import("std");

pub fn main() !void {
    // Set up buffered stdout for writing output.
    // Zig 0.15 requires an explicit buffer rather than wrigint directly.
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_impl.interface;

    // std,process.args returns an iterator over command line arguments.
    // The first arg is the filename, so we need to skip it.
    var args = std.process.args();
    _ = args.next();

    // args.next() returns an optional (?[]const u8).
    // If no fileame was provided, the orelse block runs and we exit early.
    const filename = args.next() orelse {
        try stdout.print("Usage: wc <filename>\n", .{});
        try stdout.flush();
        return;
    };

    // open the file relative to the current working directory.
    // The catch block handles any error (file not found, no permissions etc)
    // and prints a friendly message instead of crashing,
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        try stdout.print("Error opening file '{s}': {}\n", .{ filename, err });
        try stdout.flush();
        return;
    };
    // defer guarantees file.close() runs when main() exists, no matter what.
    // this is a zig's way of ensuring resources are always cleaned up.
    defer file.close();

    // Read the entire file into a stack allocated buffer (1MB max).
    // readAll() returns how may bytes were actually read.
    // contents is a slice pointing to just the valid portion of read_buffer.
    var read_buffer: [1024 * 1024]u8 = undefined;
    const bytes_read = try file.readAll(&read_buffer);
    const contents = read_buffer[0..bytes_read];

    // count lines, words, characters
    // in_word tracks weather we are currently inside a word, acting as a simple
    // two state machine: inside a word vs between words.
    var lines: usize = 0;
    var words: usize = 0;
    const chars: usize = contents.len; // const because it never changes
    var in_word = false;

    for (contents) |c| {
        // every machine increments the line counter
        if (c == '\n') lines += 1;

        if (c == ' ' or c == '\n' or c == '\t') {
            // whitespace means we have left a word (if we were in one)
            in_word = false;
        } else if (!in_word) {
            // first non-whitespace character after whitespace = new word
            in_word = true;
            words += 1;
        }
    }

    // Print the final results, aligned for readability
    try stdout.print("\nResults for: {s}\n", .{filename});
    try stdout.print("  Lines:      {d}\n", .{lines});
    try stdout.print("  Words:      {d}\n", .{words});
    try stdout.print("  Characters: {d}\n", .{chars});
    try stdout.flush();
}