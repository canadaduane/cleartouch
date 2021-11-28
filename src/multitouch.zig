const std = @import("std");

const linux = @cImport({
    @cInclude("linux/input.h");
    @cInclude("linux/input-event-codes.h");
});

fn code_lookup(code: u16) ?[]const u8 {
    return switch (code) {
        0x00 => "X", // ABS_X
        0x01 => "Y", // ABS_Y

        0x2f => "SLOT", // MT slot being modified
        0x30 => "TOUCH_MAJOR", // Major axis of touching ellipse
        0x31 => "TOUCH_MINOR", // Minor axis (omit if circular)
        0x32 => "WIDTH_MAJOR", // Major axis of approaching ellipse
        0x33 => "WIDTH_MINOR", // Minor axis (omit if circular)
        0x34 => "ORIENTATION", // Ellipse orientation
        0x35 => "POSITION_X", // Center X touch position
        0x36 => "POSITION_Y", // Center Y touch position
        0x37 => "TOOL_TYPE", // Type of touching device
        0x38 => "BLOB_ID", // Group a set of packets as a blob
        0x39 => "TRACKING_ID", // Unique ID of initiated contact
        0x3a => "PRESSURE", // Pressure on contact area
        0x3b => "DISTANCE", // Contact hover distance
        0x3c => "TOOL_X", // Center X tool position
        0x3d => "TOOL_Y", // Center Y tool position

        0x145 => "BTN_TOOL_FINGER",
        0x14a => "BTN_TOUCH",
        0x14d => "BTN_TOOL_DOUBLETAP",

        else => null,
    };
}

const MAX_TOUCH_POINTS = 10;
var _start_time: i64 = -1;

pub const InputEvent = extern struct {
    time: linux.timeval,
    type: u16,
    code: u16,
    value: i32,

    fn print_evt(input: *const InputEvent, name: []const u8) void {
        if (code_lookup(input.code)) |code_name| {
            std.debug.print(
                "  {s}({s}, {d})\n",
                .{ name, code_name, input.value },
            );
        } else {
            std.debug.print(
                "  {s}(0x{X}, {d})\n",
                .{ name, input.code, input.value },
            );
        }
    }

    fn print_timed_evt(input: *const InputEvent, name: []const u8) void {
        if (_start_time < 0) _start_time = std.time.timestamp();
        // use time relative to the start of the program
        const time: f64 =
            std.math.lossyCast(f64, input.time.tv_sec - _start_time) +
            std.math.lossyCast(f64, input.time.tv_usec) / 1e6;
        std.debug.print(
            "  {s}(0x{X}, {d}) @ {d:.3}s\n",
            .{ name, input.code, input.value, time },
        );
    }

    pub fn print(input: *const InputEvent) void {
        switch (input.type) {
            linux.EV_KEY => input.print_evt("EV_KEY"),
            linux.EV_ABS => input.print_evt("EV_ABS"),
            linux.EV_MSC => input.print_evt("EV_MSC"),
            linux.EV_SYN => input.print_evt("EV_SYN"),
            else => std.debug.print(
                "  EV(0x{X}, 0x{X}, {d})\n",
                .{ input.type, input.code, input.value },
            ),
        }
    }
};

const TouchData = struct {
    used: bool = false,
    pressed: bool = false,
    pressed_double: bool = false,

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

    fn set(self: *TouchData, comptime field: []const u8, value: anytype) void {
        self.used = true;
        @field(self, field) = value;
    }

    pub fn reset(self: *TouchData) void {
        self.used = false;
        self.pressed = false;
        self.pressed_double = false;

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
        }
    }

    pub fn process(self: *MTStateMachine, input: *const InputEvent) !void {
        switch (input.type) {
            linux.EV_KEY => {
                switch (input.code) {
                    linux.BTN_TOUCH => {
                        self.touches[0].pressed = (input.value == 1);
                    },
                    linux.BTN_TOOL_DOUBLETAP => {
                        self.touches[0].pressed_double = (input.value == 1);
                    },
                    else => {},
                }
            },
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
                    linux.ABS_MT_POSITION_X => touch.set("position_x", input.value),
                    linux.ABS_MT_POSITION_Y => touch.set("position_y", input.value),

                    linux.ABS_MT_PRESSURE => touch.set("pressure", input.value),
                    linux.ABS_MT_DISTANCE => touch.set("distance", input.value),

                    linux.ABS_MT_TOUCH_MAJOR => touch.set("touch_major", input.value),
                    linux.ABS_MT_TOUCH_MINOR => touch.set("touch_minor", input.value),
                    linux.ABS_MT_WIDTH_MAJOR => touch.set("width_major", input.value),
                    linux.ABS_MT_WIDTH_MINOR => touch.set("width_minor", input.value),
                    linux.ABS_MT_ORIENTATION => touch.set("orientation", input.value),

                    linux.ABS_MT_TOOL_X => touch.set("tool_x", input.value),
                    linux.ABS_MT_TOOL_Y => touch.set("tool_y", input.value),
                    linux.ABS_MT_TOOL_TYPE => touch.set("tool_type", input.value),
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
