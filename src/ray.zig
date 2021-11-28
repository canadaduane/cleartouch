pub const ray = @cImport({
    @cInclude("raylib.h");
});

pub usingnamespace ray;

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
