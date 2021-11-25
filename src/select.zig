const std = @import("std");

const FdSet = std.StaticBitSet(1024);
comptime {
    std.debug.assert(@sizeOf(FdSet) == 1024 / 8);
}
pub fn select(
    nfds: isize,
    readfds: ?*FdSet,
    writefds: ?*FdSet,
    exceptfds: ?*FdSet,
    timeout: ?*const std.os.linux.timeval,
) usize {
    return std.os.linux.syscall5(
        .select5,
        @bitCast(usize, nfds),
        @ptrToInt(readfds),
        @ptrToInt(writefds),
        @ptrToInt(exceptfds),
        @ptrToInt(timeout),
    );
}

pub fn select_read()