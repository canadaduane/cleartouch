const std = @import("std");

const raylibFlags = &[_][]const u8{
    "-std=gnu99",
    "-DPLATFORM_DESKTOP",
    "-DGL_SILENCE_DEPRECATION",
    "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/1891
};

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Sandbox

    const sandbox_exe = b.addExecutable("sandbox", "src/sandbox.zig");

    sandbox_exe.setTarget(target);

    sandbox_exe.setBuildMode(mode);

    sandbox_exe.install();

    const sandbox_cmd = sandbox_exe.run();
    sandbox_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        sandbox_cmd.addArgs(args);
    }

    const sandbox_step = b.step("sandbox", "Run the sandbox");
    sandbox_step.dependOn(&sandbox_cmd.step);

    // Main

    const main_exe = b.addExecutable("cleartouch", "src/main.zig");

    main_exe.addIncludeDir("raylib/include");
    main_exe.addLibPath("raylib/lib");

    main_exe.setTarget(target);

    main_exe.setBuildMode(mode);

    main_exe.linkLibC();
    main_exe.addIncludeDir("./lib/raylib/src");
    main_exe.addIncludeDir("./lib/raylib/src/external/glfw/include");
    main_exe.addCSourceFile("./lib/raylib/src/rcore.c", raylibFlags);
    main_exe.addCSourceFile("./lib/raylib/src/rmodels.c", raylibFlags);
    main_exe.addCSourceFile("./lib/raylib/src/raudio.c", raylibFlags);
    main_exe.addCSourceFile("./lib/raylib/src/rshapes.c", raylibFlags);
    main_exe.addCSourceFile("./lib/raylib/src/rtext.c", raylibFlags);
    main_exe.addCSourceFile("./lib/raylib/src/rtextures.c", raylibFlags);
    main_exe.addCSourceFile("./lib/raylib/src/utils.c", raylibFlags);
    main_exe.addCSourceFile("./lib/raylib/src/rglfw.c", raylibFlags);

    main_exe.linkSystemLibrary("GL");
    main_exe.linkSystemLibrary("rt");
    main_exe.linkSystemLibrary("dl");
    main_exe.linkSystemLibrary("m");
    main_exe.linkSystemLibrary("X11");

    main_exe.install();

    const run_cmd = main_exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

}