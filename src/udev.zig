const std = @import("std");
const mem = std.mem;
const os = std.os;
const c = @cImport({
    @cInclude("linux/hidraw.h");
    @cInclude("libudev.h");
    @cInclude("sys/ioctl.h");
});

pub fn open_touchpad() anyerror!os.fd_t {
    const context = c.udev_new() orelse
        return error.@"Failed to create udev context";
    defer _ = c.udev_unref(context);

    const devices = c.udev_enumerate_new(context) orelse
        return error.@"Failed to create enumerator";
    defer _ = c.udev_enumerate_unref(devices);

    if (c.udev_enumerate_add_match_subsystem(devices, "input") < 0) {
        return error.@"No input devices available";
    }

    if (c.udev_enumerate_add_match_property(devices, "ID_INPUT_TOUCHPAD", "1") < 0) {
        return error.@"No touchpad devices available";
    }

    if (c.udev_enumerate_scan_devices(devices) < 0) {
        return error.@"Scan failed";
    }

    var entry = c.udev_enumerate_get_list_entry(devices);

    while (entry) |node| : (entry = c.udev_list_entry_get_next(node)) {
        const name = mem.sliceTo(c.udev_list_entry_get_name(node), 0);
        // std.log.debug("{s}", .{name});
        if (mem.indexOf(u8, name, "/event") != null) {
            std.log.debug("found device: {s}", .{name});

            const dev = c.udev_device_new_from_syspath(
                context,
                c.udev_list_entry_get_name(node),
            ) orelse
                return error.@"Failed to get device from syspath";
            defer _ = c.udev_device_unref(dev);

            const devnode = mem.sliceTo(c.udev_device_get_devnode(dev), 0);
            std.log.debug("devnode: {s}", .{devnode});

            return try os.open(devnode, os.O.RDONLY | os.O.NONBLOCK, 0);
        }
    }
    return os.OpenError.FileNotFound;
}