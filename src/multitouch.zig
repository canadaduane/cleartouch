const linux = @cImport({
    @cInclude("input.h");
    @cInclude("input-event-codes.h");
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

