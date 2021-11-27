const std = @import("std");

const raylibFlags = &[_][]const u8{
    "-std=gnu99",
    "-DPLATFORM_DESKTOP",
    "-DGL_SILENCE_DEPRECATION",
    "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/1891
};

fn addRayLib(exe: *std.build.LibExeObjStep) void {
    exe.addIncludeDir("raylib/include");
    exe.addLibPath("raylib/lib");
    
    exe.addIncludeDir("./lib/raylib/src");
    exe.addIncludeDir("./lib/raylib/src/external/glfw/include");
    
    exe.addCSourceFile("./lib/raylib/src/rcore.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rmodels.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/raudio.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rshapes.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rtext.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rtextures.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/utils.c", raylibFlags);
    exe.addCSourceFile("./lib/raylib/src/rglfw.c", raylibFlags);

    exe.linkSystemLibrary("GL");
    exe.linkSystemLibrary("rt");
    exe.linkSystemLibrary("dl");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("X11");
}

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    // Sandbox

    const sandbox_exe = b.addExecutable("sandbox", "src/sandbox.zig");
    sandbox_exe.setTarget(target);
    sandbox_exe.setBuildMode(mode);

    sandbox_exe.linkLibC();
    sandbox_exe.linkSystemLibrary("libudev");

    addRayLib(sandbox_exe);

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


    main_exe.setTarget(target);
    main_exe.setBuildMode(mode);

    main_exe.linkLibC();
    main_exe.linkSystemLibrary("libudev");

    addRayLib(main_exe);
    main_exe.addPackagePath("pike", "lib/pike/pike.zig");

    main_exe.install();

    const run_cmd = main_exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
