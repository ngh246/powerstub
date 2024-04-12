const std = @import("std");

const do_log_crap = false;

const Action = enum {
    none,
    start,

    fn fromStr(str: []const u8) Action {
        if (std.ascii.eqlIgnoreCase("Start-Process", str)) {
            return .start;
        }
        return .none;
    }
};

// Work around a Wine bug: `(echo %ERRORLEVEL%) > somewhere`
// doesn't redirect the output to somewhere.
fn workaroundWineBatchBug(allocator: std.mem.Allocator, filename: []const u8) void {
    const buggy = "(echo %ERRORLEVEL%) >";
    const workaround = "echo %ERRORLEVEL% >";
    const buf = std.fs.cwd().readFileAlloc(allocator, filename, 1024 * 512) catch return;
    const fixed_buf = allocator.alloc(u8, buf.len) catch return;
    const replacements = std.mem.replace(u8, buf, buggy, workaround, fixed_buf);
    if (replacements > 0) {
        var workaround_file = std.fs.cwd().createFile(filename, .{}) catch return;
        defer workaround_file.close();
        _ = workaround_file.write(fixed_buf[0 .. fixed_buf.len - (replacements * 2)]) catch return;
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.skip();
    const action = Action.fromStr(args.next() orelse return);
    switch (action) {
        .start => {
            var actually_execute = true;
            var maybe_file_path: ?[]const u8 = null;
            while (args.next()) |arg| {
                if (std.ascii.eqlIgnoreCase(arg, "-FilePath")) {
                    const value = args.next() orelse break;
                    // This will probably not work if the path has spaces in it!
                    maybe_file_path = std.mem.trim(u8, value, "'");
                } else if (std.ascii.eqlIgnoreCase(arg, "-powerstub-pls-dont-start")) {
                    // I hope nothing else uses that..
                    actually_execute = false;
                }
            }
            if (maybe_file_path) |file_path| {
                if (std.mem.endsWith(u8, file_path, ".bat")) {
                    workaroundWineBatchBug(allocator, file_path);
                }
                if (actually_execute) {
                    const ret = try std.process.Child.run(.{
                        .allocator = allocator,
                        .argv = &.{ "start", file_path },
                    });
                    if (do_log_crap) {
                        var logfile = try std.fs.cwd().createFile("C:\\powerstublog.log", .{});
                        defer logfile.close();
                        var writer = logfile.writer();
                        try writer.print("ran {s}\nterm {}\n", .{ file_path, ret.term });
                        try writer.writeAll("--stdout--\n");
                        try writer.writeAll(ret.stdout);
                        try writer.writeAll("--stderr--\n");
                        try writer.writeAll(ret.stderr);
                    }
                }
            }
        },
        .none => return,
    }
}
