const std = @import("std");
const os = std.os;
const ray = @cImport({
    @cInclude("raylib.h");
});
const udev = @import("udev.zig");

const ORANGE =
    ray.Color{ .r = 255, .g = 161, .b = 0, .a = 255 };
const MAX_TOUCH_POINTS = 10;
const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

pub fn main() anyerror!void {
    const fd = try udev.open_touchpad();
    defer os.close(fd); //udev.close_touchpad(fd);

    // var poll_fds = [_]os.pollfd{
    //     .{ .fd = fd, .events = os.POLLIN, .revents = undefined },
    // };

    // const events = try os.poll(&poll_fds, std.math.maxInt(i32));
    // if (events == 0) continue;

    // https://gist.github.com/marler8997/7f2e1b6a3ce938285c620c642c3e581a


    // ray.InitWindow(
    //     SCREEN_WIDTH,
    //     SCREEN_HEIGHT,
    //     "Cleartouch - Touchpad Visualizer",
    // );
    // defer ray.CloseWindow();

    // ray.SetTargetFPS(60);

    // var touchPositions: [MAX_TOUCH_POINTS]ray.Vector2 =
    //     [1]ray.Vector2{std.mem.zeroes(ray.struct_Vector2)} ** MAX_TOUCH_POINTS;

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
    // }
}
