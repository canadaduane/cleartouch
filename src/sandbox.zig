const std = @import("std");
const mt = @import("multitouch.zig");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("hmmm\n", .{});
}
