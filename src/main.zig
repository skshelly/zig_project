const std = @import("std");

pub fn main() !void {
    // Set up buffered stdout for writing output.
    // Zig 0.15 requires an explicit buffer rather than writing directly.
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.fs.File.stdout().writer(&buffer);
    const stdout = &stdout_impl.interface;

    // std.process.args() returns an iterator over command line arguments.
    // The first argument is always the program name itself, so we skip it.
    var args = std.process.args();
    _ = args.next(); // discard program name

    // args.next() returns an optional (?[]const u8).
    // If no filename was provided, the orelse block runs and we exit early.
    const filename = args.next() orelse {
        try stdout.print("Usage: wc <filename>\n", .{});
        try stdout.flush();
        return;
    };

    // Open the file relative to the current working directory.
    // catch handles any error (file not found, no permission, etc.)
    const file = std.fs.cwd().openFile(filename, .{}) catch |err| {
        try stdout.print("Error opening file '{s}': {}\n", .{ filename, err });
        try stdout.flush();
        return;
    };
    // defer guarantees file.close() runs when main() exits no matter what.
    defer file.close();

    // Read the entire file into a stack allocated buffer (1MB max).
    // contents is a slice pointing to just the valid portion of read_buffer.
    var read_buffer: [1024 * 1024]u8 = undefined;
    const bytes_read = try file.readAll(&read_buffer);
    const contents = read_buffer[0..bytes_read];

    // --- Standard counts ---

    // Count lines with a simple pass looking for newline characters.
    var lines: usize = 0;
    for (contents) |c| {
        if (c == '\n') lines += 1;
    }

    // Total bytes in file including all whitespace.
    const total_chars: usize = contents.len;

    // --- Token based counts (ML friendly) ---

    // tokenizeAny splits on any of the given delimiter characters.
    // Each token is a slice of the original contents (no allocation needed).
    // Whitespace characters (space, newline, tab) are the delimiters.
    var tokenizer = std.mem.tokenizeAny(u8, contents, " \n\t");

    var token_count: usize = 0;
    var non_whitespace_chars: usize = 0;

    while (tokenizer.next()) |token| {
        token_count += 1;                  // each token is one word
        non_whitespace_chars += token.len; // sum character lengths
    }

    // --- Output ---
    try stdout.print("\nResults for: {s}\n", .{filename});
    try stdout.print("\n  -- Standard --\n", .{});
    try stdout.print("  Lines:                 {d}\n", .{lines});
    try stdout.print("  Words:                 {d}\n", .{token_count});
    try stdout.print("  Total characters:      {d}\n", .{total_chars});
    try stdout.print("\n  -- ML Friendly --\n", .{});
    try stdout.print("  Tokens:                {d}\n", .{token_count});
    try stdout.print("  Non-whitespace chars:  {d}\n", .{non_whitespace_chars});
    try stdout.flush();
}