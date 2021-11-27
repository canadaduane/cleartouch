const std = @import("std");

const MAX_TOUCH_POINTS = 10;

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

        switch (input.type) {
            linux.EV_KEY => try std.fmt.format(
                writer,
                "  EV_KEY(0x{X}, {d}) ({d:.3})\n",
                .{ input.code, input.value, time },
            ),
            linux.EV_ABS => try std.fmt.format(
                writer,
                "  EV_ABS(0x{X}, {d}) ({d:.3})\n",
                .{ input.code, input.value, time },
            ),
            linux.EV_MSC => try std.fmt.format(
                writer,
                "  EV_MSC(0x{X}, {d}) ({d:.3})\n",
                .{ input.code, input.value, time },
            ),
            linux.EV_SYN => try std.fmt.format(
                writer,
                "  EV_SYN() ({d:.3})\n",
                .{time},
            ),
            else => try std.fmt.format(
                writer,
                "  EV(0x{X}, 0x{X}, {d}) ({d:.3})\n",
                .{ input.type, input.code, input.value, time },
            ),
        }
    }
};

const TouchData = struct {
    used: bool = false,

    tracking_id: i32 = -1,

    position_x: i32,
    position_y: i32,

    pressure: i32,
    distance: i32,

    touch_major: i32,
    touch_minor: i32,
    width_major: i32,
    width_minor: i32,
    orientation: i32,

    tool_x: i32,
    tool_y: i32,
    tool_type: i32,

    pub fn reset(self: *TouchData) void {
        self.used = false;

        self.tracking_id = -1;

        self.position_x = 0;
        self.position_y = 0;

        self.pressure = 0;
        self.distance = 0;

        self.touch_major = 0;
        self.touch_minor = 0;
        self.width_major = 0;
        self.width_minor = 0;
        self.orientation = 0;

        self.tool_x = 0;
        self.tool_y = 0;
        self.tool_type = 0;
    }
};

const MTError = error{ SlotOutOfBounds, SlotIsNull, BadState };

const MTState = enum {
    loading,
    read_ready,
    needs_reset,
};

pub const MTStateMachine = struct {
    state: MTState = MTState.loading,

    slot: ?usize = null,

    touches: [MAX_TOUCH_POINTS]TouchData =
        [1]TouchData{std.mem.zeroes(TouchData)} ** MAX_TOUCH_POINTS,

    pub fn reset(self: *MTStateMachine) void {
        self.state = MTState.loading;

        self.slot = null;

        for (self.touches) |_, i| {
            self.touches[i].used = false;
            // touch.used = false;
        }
    }

    // fn set_slot(comptime field, slot: i32, value: i32) !void {
    // }

    pub fn process(self: *MTStateMachine, input: *const InputEvent) !void {
        switch (input.type) {
            linux.EV_KEY => {},
            linux.EV_ABS => {
                switch (self.state) {
                    MTState.loading => {},
                    MTState.needs_reset => self.reset(),
                    MTState.read_ready => {}, // return MTError.BadState,
                }

                const slot = self.slot orelse 0;
                const touch = &self.touches[slot];
                switch (input.code) {
                    linux.ABS_MT_SLOT => {
                        if (input.value >= 0 and input.value < MAX_TOUCH_POINTS) {
                            self.slot = @intCast(usize, input.value);
                            self.touches[self.slot.?].used = true;
                        } else {
                            return MTError.SlotOutOfBounds;
                        }
                    },
                    linux.ABS_MT_TRACKING_ID => {
                        if (input.value < 0) {
                            touch.used = false;
                        } else {
                            touch.tracking_id = input.value;
                        }
                    },
                    linux.ABS_MT_TOUCH_MAJOR => touch.touch_major = input.value,
                    linux.ABS_MT_TOUCH_MINOR => touch.touch_minor = input.value,
                    linux.ABS_MT_POSITION_X => touch.position_x = input.value,
                    linux.ABS_MT_POSITION_Y => touch.position_y = input.value,
                    else => {},
                }
            },
            linux.EV_MSC => {},
            linux.EV_SYN => {
                self.state = MTState.read_ready;
            },
            else => {},
        }
    }

    pub fn is_read_ready(self: *MTStateMachine) bool {
        return self.state == MTState.read_ready;
    }
};
