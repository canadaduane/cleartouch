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

    const fd: os.fd_t = udev.open_touchpad() catch |err| {
        std.debug.print("Unable to open touchpad: {s}\n", .{err});
        std.os.exit(1);
    };
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
                if (!touch.used) continue;

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
