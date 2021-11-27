const std = @import("std");

const linux = @cImport({
    @cInclude("linux/input.h");
    @cInclude("linux/input-event-codes.h");
});

const MultitouchTool = enum(c_uint) {
    finger = linux.MT_TOOL_FINGER,
    pen = linux.MT_TOOL_PEN,
    palm = linux.MT_TOOL_PALM,
    dial = linux.MT_TOOL_DIAL,
    max = linux.MT_TOOL_MAX,
};

const MultitouchEvent = enum(c_uint) {
    reserved = linux.ABS_RESERVED,
    slot = linux.ABS_MT_SLOT, // MT slot being modified
    touch_major = linux.ABS_MT_TOUCH_MAJOR, // Major axis of touching ellipse
    touch_minor = linux.ABS_MT_TOUCH_MINOR, // Minor axis (omit if circular)
    width_major = linux.ABS_MT_WIDTH_MAJOR, // Major axis of approaching ellipse
    width_minor = linux.ABS_MT_WIDTH_MINOR, // Minor axis (omit if circular)
    orientation = linux.ABS_MT_ORIENTATION, // Ellipse orientation
    position_x = linux.ABS_MT_POSITION_X, // Center X touch position
    position_y = linux.ABS_MT_POSITION_Y, // Center Y touch position
    tool_type = linux.ABS_MT_TOOL_TYPE, // Type of touching device
    blob_id = linux.ABS_MT_BLOB_ID, // Group a set of packets as a blob
    tracking_id = linux.ABS_MT_TRACKING_ID, // Unique ID of initiated contact
    pressure = linux.ABS_MT_PRESSURE, // Pressure on contact area
    distance = linux.ABS_MT_DISTANCE, // Contact hover distance
    tool_x = linux.ABS_MT_TOOL_X, // Center X tool position
    tool_y = linux.ABS_MT_TOOL_Y, // Center Y tool position

    max = linux.ABS_MAX,
    count = linux.ABS_CNT,
};

var _start_time: i64 = -1;

pub const InputEvent = extern struct {
    time: linux.timeval,
    type: u16,
    code: u16,
    value: i32,

    pub fn format(
        input: *const InputEvent,
        writer: anytype,
    ) !void {
        if (_start_time < 0) _start_time = std.time.timestamp();
        // use time relative to the start of the program
        const time: f64 =
            std.math.lossyCast(f64, input.time.tv_sec - _start_time) +
            std.math.lossyCast(f64, input.time.tv_usec) / 1e6;
        try std.fmt.format(writer, "{{EV({d}, {d}, {d}) ({d:.3})}}", .{ input.type, input.value, input.code, time });
    }
};
