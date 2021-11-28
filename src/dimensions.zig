const ray = @import("ray.zig");

pub const Dimensions = struct {
    touchpad_max_extent_x: f32,
    touchpad_max_extent_y: f32,

    screen_width: f32,
    screen_height: f32,

    margin: f32,

    pub fn getTouchpadCorner(self: *Dimensions, scale: f32) ray.Vector2 {
        return ray.Vector2{
            .x = self.screen_width / 2 - (self.touchpad_max_extent_x / 2) * scale,
            .y = self.screen_height / 2 - (self.touchpad_max_extent_y / 2) * scale,
        };
    }

    pub fn getTouchpadScale(self: *Dimensions) f32 {
        if (self.touchpad_max_extent_x > self.touchpad_max_extent_y) {
            return self.screen_width /
                (self.touchpad_max_extent_x + self.margin * 2);
        } else {
            return self.screen_height /
                (self.touchpad_max_extent_y + self.margin * 2);
        }
    }

    pub fn maybeGrowTouchpadExtent(self: *Dimensions, x: f32, y: f32) void {
        if (self.touchpad_max_extent_x < x)
            self.touchpad_max_extent_x = x;
        if (self.touchpad_max_extent_y < y)
            self.touchpad_max_extent_y = y;
    }
};

