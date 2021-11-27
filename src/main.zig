const std = @import("std");
const os = std.os;
const mt = @import("multitouch.zig");
const udev = @import("udev.zig");
const pike = @import("pike");

const ray = @cImport({
    @cInclude("raylib.h");
});

const ORANGE =
    ray.Color{ .r = 255, .g = 161, .b = 0, .a = 255 };
const SCREEN_WIDTH = 1200;
const SCREEN_HEIGHT = 800;

const log = std.log;

var machine = mt.MTStateMachine{};

pub fn main() !void {
    try pike.init();
    defer pike.deinit();

    const notifier = try pike.Notifier.init();
    defer notifier.deinit();

    const fd: os.fd_t = try udev.open_touchpad();
    defer udev.close_touchpad(fd);

    // Initialize visual
    ray.InitWindow(
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        "Cleartouch - Touchpad Visualizer",
    );
    defer ray.CloseWindow();
    ray.SetTargetFPS(60);

    const handle: pike.Handle = .{ .inner = fd, .wake_fn = wake };
    try notifier.register(&handle, .{ .read = true, .write = false });

    var iter: u64 = 0;
    while (true) : (iter += 1) {
        try notifier.poll(10);
        // std.debug.print("loop {}\n", .{iter});

        if (ray.WindowShouldClose()) break;

        {
            ray.BeginDrawing();
            defer ray.EndDrawing();

            ray.ClearBackground(ray.RAYWHITE);

            for (machine.touches) |touch, i| {
                const pos: ray.Vector2 = ray.Vector2{
                    .x = @intToFloat(f32, touch.position_x),
                    .y = @intToFloat(f32, touch.position_y),
                };
                ray.DrawCircleV(pos, 34, ORANGE);
                ray.DrawText(
                    ray.TextFormat("%d", i),
                    @floatToInt(c_int, pos.x - 10),
                    @floatToInt(c_int, pos.y - 70),
                    40,
                    ray.BLACK,
                );
            }
        }
    }

    // while (!ray.WindowShouldClose()) {
    //     ray.BeginDrawing();
    //     defer ray.EndDrawing();

    //     {
    //         var i: u64 = 0;
    //         while (i < MAX_TOUCH_POINTS) : (i += 1) {
    //             touchPositions[i] = ray.GetTouchPosition(@intCast(c_int, i));
    //         }
    //     }

    //     ray.ClearBackground(ray.RAYWHITE);

    //     {
    //         var i: c_uint = 0;
    //         while (i < MAX_TOUCH_POINTS) : (i += 1) {
    //             if ((touchPositions[i].x > 0) and (touchPositions[i].y > 0)) {
    //                 ray.DrawCircleV(touchPositions[i], 34, ORANGE);
    //                 ray.DrawText(
    //                     ray.TextFormat("%d", i),
    //                     @floatToInt(c_int, touchPositions[i].x - 10),
    //                     @floatToInt(c_int, touchPositions[i].y - 70),
    //                     40,
    //                     ray.BLACK,
    //                 );
    //             }
    //         }
    //     }
}

fn wake(handle: *pike.Handle, batch: *pike.Batch, opts: pike.WakeOptions) void {
    const stdout = std.io.getStdOut().writer();
    // var events: [100]mt.InputEvent = std.mem.zeroes([100]mt.InputEvent);
    var events: [100]mt.InputEvent = undefined;
    if (opts.read_ready) {
        // const bytes = os.read(handle.inner, @ptrCast([*]u8, &events));
        const bytes = os.read(handle.inner, std.mem.sliceAsBytes(events[0..])) catch 0;
        if (bytes == 0) {
            std.debug.print("read 0 bytes\n", .{});
            return;
        }

        const inputEventSize: usize = @intCast(usize, @sizeOf(mt.InputEvent));
        const eventCount: usize = @divExact(bytes, inputEventSize);
        std.debug.print("fd: {d}, {d}\n", .{ handle.inner, bytes });

        for (events[0..eventCount]) |event| {
            event.format(stdout) catch std.debug.print("uhoh\n", .{});
            machine.process(&event) catch |err| {
                std.debug.print("can't process: {}\n", .{err});
            };
        }
        // std.debug.print("{s}", .{events});
    }
    _ = batch;
}
