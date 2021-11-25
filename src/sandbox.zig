const std = @import("std");

// NOTE: it's lucky that StaticBitSet has the right memory layout
//       it may not in the future or on some platforms
const FdSet = std.StaticBitSet(1024);
comptime {
    // make sure our FdSet is right
    std.debug.assert(@sizeOf(FdSet) == 1024 / 8);
}
pub fn pselect6(
    nfds: isize,
    readfds: ?*FdSet,
    writefds: ?*FdSet,
    exceptfds: ?*FdSet,
    timeout: ?*const std.os.linux.timespec,
    sigmask: ?*const std.os.linux.sigset_t,
) usize {
    return std.os.linux.syscall6(
        .pselect6,
        @bitCast(usize, nfds),
        @ptrToInt(readfds),
        @ptrToInt(writefds),
        @ptrToInt(exceptfds),
        @ptrToInt(timeout),
        @ptrToInt(sigmask),
    );
}

pub fn main() !void {
    const fd1 = 0;
    const fd2 = 1;

    std.log.debug("Started.\n", .{});

    const maxfd = std.math.max(fd1, fd2) + 1;
    var iter: u64 = 0;
    while (true) {
        std.log.debug("iter: {d}", .{iter});
        iter += 1;

        var readfds = FdSet.initEmpty();
        readfds.setValue(fd1, true);
        readfds.setValue(fd2, true);

        switch (std.os.errno(pselect6(maxfd, &readfds, null, null, null, null))) {
            .SUCCESS => {},
            else => |errno| {
                std.log.err("select failed, errno={}", .{errno});
                std.os.exit(0xff);
            },
        }

        if (readfds.isSet(fd1)) {
            var buf: [100]u8 = undefined;
            const len = try std.os.read(fd1, &buf);
            if (len > 0) {
                const slice = buf[0..len];
                std.log.debug("fd1: {s}", .{slice});
            }
        } else if (readfds.isSet(fd2)) {
            var buf: [100]u8 = undefined;
            const len = try std.os.read(fd2, &buf);
            if (len > 0) {
                const slice = buf[0..len];
                std.log.debug("fd2: {s}", .{slice});
            }
        }
    }
}
