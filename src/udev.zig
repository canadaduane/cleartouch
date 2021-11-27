const std = @import("std");
const mem = std.mem;
const os = std.os;
const linux = @cImport({
    @cInclude("linux/hidraw.h");
    @cInclude("libudev.h");
    @cInclude("sys/ioctl.h");
    // for EVIOCGRAB:
    @cInclude("linux/input.h");
});

const UNGRAB = 0;
const GRAB = 1;

const DeviceError = error{ CantGrab, NotFound };

pub fn open_touchpad() !os.fd_t {
    const context = linux.udev_new() orelse
        return error.@"Failed to create udev context";
    defer _ = linux.udev_unref(context);

    const devices = linux.udev_enumerate_new(context) orelse
        return error.@"Failed to create enumerator";
    defer _ = linux.udev_enumerate_unref(devices);

    if (linux.udev_enumerate_add_match_subsystem(devices, "input") < 0) {
        return error.@"No input devices available";
    }

    if (linux.udev_enumerate_add_match_property(devices, "ID_INPUT_TOUCHPAD", "1") < 0) {
        return error.@"No touchpad devices available";
    }

    if (linux.udev_enumerate_scan_devices(devices) < 0) {
        return error.@"Scan failed";
    }

    var entry = linux.udev_enumerate_get_list_entry(devices);

    while (entry) |node| : (entry = linux.udev_list_entry_get_next(node)) {
        const name = mem.sliceTo(linux.udev_list_entry_get_name(node), 0);
        if (mem.indexOf(u8, name, "/event") != null) {
            // std.debug.print("Found touchpad: {s}\n", .{name});

            const dev = linux.udev_device_new_from_syspath(
                context,
                linux.udev_list_entry_get_name(node),
            ) orelse
                return error.@"Failed to get device from syspath";
            defer _ = linux.udev_device_unref(dev);

            const devnode = mem.sliceTo(linux.udev_device_get_devnode(dev), 0);
            std.debug.print("Found touchpad: {s}\n", .{devnode});

            const fd = try os.open(devnode, os.O.RDONLY | os.O.NONBLOCK, 0);

            if (std.os.linux.ioctl(fd, linux.EVIOCGRAB, GRAB) < 0) {
                return DeviceError.CantGrab;
            }

            return fd;
        }
    }
    return DeviceError.NotFound;
}

pub fn close_touchpad(fd: os.fd_t) void {
    const success = std.os.linux.ioctl(fd, linux.EVIOCGRAB, UNGRAB);
    if (success < 0) {
        std.debug.print("Can't ungrab device");
    }
    os.close(fd);
}

