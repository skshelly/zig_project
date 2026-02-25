const std = @import("std");

// ─────────────────────────────────────────────
//  Error helpers
// ─────────────────────────────────────────────

/// Translates a file open error into a human readable message.
/// Isolates error messaging from file processing logic.
fn fileErrorMessage(err: anyerror) []const u8 {
    return switch (err) {
        error.FileNotFound => "file does not exist",
        error.AccessDenied => "permission denied",
        error.IsDir        => "path is a directory not a file",
        error.FileBusy     => "file is currently locked",
        else               => "unexpected error",
    };
}

// ─────────────────────────────────────────────
//  Counting
// ─────────────────────────────────────────────

/// Holds the results of analysing a file.
const WordCount = struct {
    lines:               usize,
    words:               usize,
    total_chars:         usize,
    non_whitespace_chars: usize,
};

/// Analyses the contents of a file and returns a WordCount.
/// Separating counting logic from I/O makes this easy to test.
fn countContents(contents: []const u8) WordCount {
    // count lines
    var lines: usize = 0;
    for (contents) |c| {
        if (c == '\n') lines += 1;
    }

    // count tokens and non-whitespace characters
    var tokenizer = std.mem.tokenizeAny(u8, contents, " \n\t\r");
    var words: usize = 0;
    var non_whitespace_chars: usize = 0;
    while (tokenizer.next()) |token| {
        words += 1;
        non_whitespace_chars += token.len;
    }

    return WordCount{
        .lines                = lines,
        .words                = words,
        .total_chars          = contents.len,
        .non_whitespace_chars = non_whitespace_chars,
    };
}

// ─────────────────────────────────────────────
//  Output
// ─────────────────────────────────────────────

/// Prints the word count results in a formatted table.
/// Separating output from logic makes it easy to change
/// formatting without touching the counting code.
fn printResults(
    stdout: anytype,
    filename: []const u8,
    wc: WordCount,
) !void {
    try stdout.print("\nResults for: {s}\n", .{filename});
    try stdout.print("\n  -- Standard --\n", .{});
    try stdout.print("  Lines:                 {d}\n", .{wc.lines});
    try stdout.print("  Words:                 {d}\n", .{wc.words});
    try stdout.print("  Total characters:      {d}\n", .{wc.total_chars});
    try stdout.print("\n  -- ML Friendly --\n", .{});
    try stdout.print("  Tokens:                {d}\n", .{wc.words});
    try stdout.print("  Non-whitespace chars:  {d}\n", .{wc.non_whitespace_chars});
    try stdout.flush();
}

// ─────────────────────────────────────────────
//  Entry point
// ─────────────────────────────────────────────

/// main() is purely an orchestrator:
///   1. parse arguments
///   2. open file
///   3. read file
///   4. count contents
///   5. print results
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
        try stdout.print("Error opening '{s}': {s}\n", .{ filename, fileErrorMessage(err) });
        try stdout.flush();
        return;
    };
    defer file.close();

    var read_buffer: [1024 * 1024]u8 = undefined;
    const bytes_read = try file.readAll(&read_buffer);
    const contents = read_buffer[0..bytes_read];

    const wc = countContents(contents);
    try printResults(stdout, filename, wc);
}


// ─────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────

test "empty file returns all zeros" {
    const result = countContents("");
    try std.testing.expectEqual(@as(usize, 0), result.lines);
    try std.testing.expectEqual(@as(usize, 0), result.words);
    try std.testing.expectEqual(@as(usize, 0), result.total_chars);
    try std.testing.expectEqual(@as(usize, 0), result.non_whitespace_chars);
}

test "single line single word" {
    const result = countContents("hello");
    try std.testing.expectEqual(@as(usize, 0), result.lines);
    try std.testing.expectEqual(@as(usize, 1), result.words);
    try std.testing.expectEqual(@as(usize, 5), result.total_chars);
    try std.testing.expectEqual(@as(usize, 5), result.non_whitespace_chars);
}

test "whitespace only" {
    const result = countContents("\n \n \n");
    try std.testing.expectEqual(@as(usize, 3), result.lines);
    try std.testing.expectEqual(@as(usize, 0), result.words);
    try std.testing.expectEqual(@as(usize, 5), result.total_chars);
    try std.testing.expectEqual(@as(usize, 0), result.non_whitespace_chars);
}

test "windows line ending" {
    const result = countContents("hello\r\nworld\r\n");
    try std.testing.expectEqual(@as(usize, 2), result.lines);
    try std.testing.expectEqual(@as(usize, 2), result.words);
    try std.testing.expectEqual(@as(usize, 14), result.total_chars);
    try std.testing.expectEqual(@as(usize, 10), result.non_whitespace_chars);
}