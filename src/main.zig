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
// https://ss64.com/ps/syntax-esc.html
// And apparently '' is enough to escape a '
fn escapeApostrophe(allocator:std.mem.Allocator, arg:[]const u8, iterator:*std.process.ArgIterator) ![]const u8 {
    const start = iterator.inner.index-arg.len;
    const full = iterator.inner.cmd_line[start..];
    var list = try std.ArrayListUnmanaged(u8).initCapacity(allocator, arg.len);
    var in_apostrophe = false;
    var in_escape = false;
    const arg_start:usize = if (full[0] == '\'') 1 else 0;
    var part_start:usize = arg_start;
    for (full[arg_start..], arg_start..) |char, idx| {
        if (in_escape) {
            in_escape = false;
            try list.appendSlice(allocator, full[part_start..idx-1]);
            try list.append(allocator, char);
            part_start = idx+1;
            continue;
        }
        if (char == '`') {
            in_escape = true;
            continue;
        }
        if (char == '\'') {
            if (in_apostrophe) {
                in_apostrophe = false;
            } else {
                try list.appendSlice(allocator, full[part_start..idx]);
                part_start = idx+1;
                in_apostrophe = true;
            }
        } else if (in_apostrophe) {
            iterator.inner.index = start + idx;
            break;
        }
    } else {
        if (!in_apostrophe) {
            const end = if (in_escape) full.len-1 else full.len;
            try list.appendSlice(allocator, full[part_start..end]);
        }
        iterator.inner.index = iterator.inner.cmd_line.len;
    }
    return list.toOwnedSlice(allocator);
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
                    const value = blk: {
                        // Special handling for Windows. Sigh.
                        if (@import("builtin").target.os.tag == .windows) {
                            const val = args.next() orelse break;
                            if (val[0] == '\'') {
                                break :blk try escapeApostrophe(allocator, val, &args);
                            }
                            break :blk val;
                        } else {
                            break :blk args.next() orelse break;
                        }
                    };
                    maybe_file_path = value;
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
                    if (std.process.Child.run(.{
                        .allocator = allocator,
                        .argv = &.{ file_path },
                    })) |ret| {
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
                    } else |err| {
                        if (do_log_crap) {
                            var logfile = try std.fs.cwd().createFile("C:\\powerstublog.log", .{});
                            defer logfile.close();
                            var writer = logfile.writer();
                            try writer.print("failed to start \"{s}\": {s}\nfull cmdline: {s}", .{file_path, @errorName(err), args.inner.cmd_line});
                        }
                        return err;
                    }
                }
            }
        },
        .none => return,
    }
}
