pub const ray = @cImport({
    @cInclude("raylib.h");
});

pub const InitWindow = ray.InitWindow;
pub const SetTargetFPS = ray.SetTargetFPS;
pub const WindowShouldClose = ray.WindowShouldClose;
pub const CloseWindow = ray.CloseWindow;
pub const BeginDrawing = ray.BeginDrawing;
pub const EndDrawing = ray.EndDrawing;
pub const DrawCircleV = ray.DrawCircleV;
pub const DrawText = ray.DrawText;
pub const ClearBackground = ray.ClearBackground;
pub const TextFormat = ray.TextFormat;
pub const Vector2 = ray.Vector2;

pub const Color = ray.Color;
pub const WHITE = ray.WHITE;
pub const GRAY = ray.GRAY;
pub const BLACK = ray.BLACK;

pub const IsKeyPressed = ray.IsKeyPressed;
pub const SetExitKey = ray.SetExitKey;
pub const KEY_ENTER = ray.KEY_ENTER;
pub const KEY_ESCAPE = ray.KEY_ESCAPE;

pub fn DrawTextCentered(
    message: [*c]const u8,
    x: i32,
    y: i32,
    size: i32,
    color: anytype,
) void {
    const width = ray.MeasureText(message, size);
    ray.DrawText(
        message,
        x - @divFloor(width, 2),
        y - @divFloor(size, 2),
        size,
        color,
    );
}
