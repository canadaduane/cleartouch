const std = @import("std");
const os = std.os;
const pike = @import("pike");

const mt = @import("multitouch.zig");
const udev = @import("udev.zig");
const ray = @import("ray.zig");
const dim = @import("dimensions.zig");

const ORANGE = ray.Color{ .r = 255, .g = 161, .b = 0, .a = 255 };
const YELLOW = ray.Color{ .r = 245, .g = 235, .b = 0, .a = 255 };

var machine = mt.MTStateMachine{};

var dims = dim.Dimensions{
    .screen_width = 672,
    .screen_height = 432,

    .touchpad_max_extent_x = 1345.0,
    .touchpad_max_extent_y = 865.0,

    .margin = 15,
};

pub fn main() !void {
    try pike.init();
    defer pike.deinit();

    const notifier = try pike.Notifier.init();
    defer notifier.deinit();

    const fd: os.fd_t = udev.open_touchpad() catch |err| {
        std.debug.print("Unable to open touchpad: {s}\n", .{err});
        std.os.exit(1);
    };
    defer udev.close_touchpad(fd);

    // Initialize visual
    ray.SetConfigFlags(ray.FLAG_WINDOW_RESIZABLE | ray.FLAG_VSYNC_HINT);
    ray.InitWindow(
        @floatToInt(c_int, dims.screen_width),
        @floatToInt(c_int, dims.screen_height),
        "Cleartouch - Touchpad Visualizer",
    );
    defer ray.CloseWindow();
    ray.SetWindowMinSize(320, 240);
    ray.SetTargetFPS(60);

    const handle: pike.Handle = .{ .inner = fd, .wake_fn = wake };
    try notifier.register(&handle, .{ .read = true, .write = false });

    var grabbed: bool = false;
    while (true) {
        if (ray.IsWindowResized()) {
            dims.screen_width = @intToFloat(f32, ray.GetScreenWidth());
            dims.screen_height = @intToFloat(f32, ray.GetScreenHeight());
        }

        // Max poll time must be less than 16.6ms so we can animate at 60fps
        try notifier.poll(10);

        if (ray.IsKeyPressed(ray.KEY_ENTER) and !grabbed) {
            try udev.grab(fd);
            grabbed = true;
            ray.SetExitKey(0);
        } else if (ray.IsKeyPressed(ray.KEY_ESCAPE) and grabbed) {
            try udev.ungrab(fd);
            grabbed = false;
            ray.SetExitKey(ray.KEY_ESCAPE);
        } else if (ray.WindowShouldClose()) {
            break;
        }

        {
            const scale = dims.getTouchpadScale();
            const corner = dims.getTouchpadCorner(scale);

            ray.BeginDrawing();
            defer ray.EndDrawing();

            ray.ClearBackground(ray.WHITE);
            ray.DrawRectangleLines(
                @floatToInt(c_int, corner.x),
                @floatToInt(c_int, corner.y),
                @floatToInt(c_int, dims.touchpad_max_extent_x * scale),
                @floatToInt(c_int, dims.touchpad_max_extent_y * scale),
                ORANGE,
            );

            // Get max extents first
            for (machine.touches) |touch| {
                const pos = getPosFromTouch(&touch);
                dims.maybeGrowTouchpadExtent(pos.x, pos.y);
            }

            for (machine.touches) |touch, i| {
                if (!touch.used) continue;

                var pos = getPosFromTouch(&touch);
                pos.x = corner.x + pos.x * scale;
                pos.y = corner.y + pos.y * scale;

                ray.DrawCircleV(pos, 34, if (i == 0) YELLOW else ORANGE);
                if (touch.pressed_double) {
                    ray.DrawRing(pos, 14, 20, 0, 360, 64, ray.BLACK);
                }
                if (touch.pressed) {
                    ray.DrawCircleV(pos, 8, ray.BLACK);
                }
                ray.DrawText(
                    ray.TextFormat("%d", i),
                    @floatToInt(c_int, pos.x - 10),
                    @floatToInt(c_int, pos.y - 70),
                    40,
                    ray.BLACK,
                );
            }

            if (ray.IsWindowFocused()) {
                if (grabbed) {
                    ray.DrawTextCentered(
                        "Press ESC to restore focus",
                        @floatToInt(c_int, dims.screen_width / 2),
                        @floatToInt(c_int, dims.screen_height / 2),
                        30,
                        ray.GRAY,
                    );
                } else {
                    ray.DrawTextCentered(
                        "Press ENTER to grab touchpad",
                        @floatToInt(c_int, dims.screen_width / 2),
                        @floatToInt(c_int, dims.screen_height / 2),
                        30,
                        ray.GRAY,
                    );
                }
            }
        }
    }
}

fn wake(handle: *pike.Handle, batch: *pike.Batch, opts: pike.WakeOptions) void {
    var events: [100]mt.InputEvent = undefined;
    if (opts.read_ready) {
        const bytes = os.read(handle.inner, std.mem.sliceAsBytes(events[0..])) catch 0;
        if (bytes == 0) {
            std.debug.print("read 0 bytes\n", .{});
            return;
        }

        const inputEventSize: usize = @intCast(usize, @sizeOf(mt.InputEvent));
        const eventCount: usize = @divExact(bytes, inputEventSize);
        std.debug.print("fd: {d}, {d}\n", .{ handle.inner, bytes });

        for (events[0..eventCount]) |event| {
            event.print();
            machine.process(&event) catch |err| {
                std.debug.print("can't process: {}\n", .{err});
            };
        }
    }
    _ = batch;
}

fn getPosFromTouch(touch: *const mt.TouchData) ray.Vector2 {
    return ray.Vector2{
        .x = @intToFloat(f32, touch.position_x),
        .y = @intToFloat(f32, touch.position_y),
    };
}
