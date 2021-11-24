const std = @import("std");
const ray = @cImport({
    @cInclude("raylib.h");
});

const ORANGE =
    ray.Color{ .r = 255, .g = 161, .b = 0, .a = 255 };
const MAX_TOUCH_POINTS = 10;

pub fn main() void {
    const screenWidth = 800;
    const screenHeight = 450;

    ray.InitWindow(screenWidth, screenHeight, "raylib [core] example - basic window");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    var touchPositions: [MAX_TOUCH_POINTS]ray.Vector2 =
        [1]ray.Vector2{std.mem.zeroes(ray.struct_Vector2)} ** MAX_TOUCH_POINTS;

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();
        
        {
            var i: u64 = 0;
            while (i < MAX_TOUCH_POINTS) : (i += 1) {
                touchPositions[i] = ray.GetTouchPosition(@intCast(c_int, i));
            }
        }

        ray.ClearBackground(ray.RAYWHITE);

        {
            var i: c_uint = 0;
            while (i < MAX_TOUCH_POINTS) : (i += 1) {
                if ((touchPositions[i].x > 0) and (touchPositions[i].y > 0)) {
                    ray.DrawCircleV(touchPositions[i], 34, ORANGE);
                    ray.DrawText(
                        ray.TextFormat("%d", i),
                        @floatToInt(c_int, touchPositions[i].x - 10),
                        @floatToInt(c_int, touchPositions[i].y - 70),
                        40,
                        ray.BLACK,
                    );
                }
            }
        }
    }
}
