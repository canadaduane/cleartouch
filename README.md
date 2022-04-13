# Cleartouch

A graphical visualization of your Linux touchpad device's input.

Cleartouch grabs your `/dev/input/event*` data stream and interprets the kernel multitouch events so they can be represented visually on a 2d canvas (via raylib).

![screenshot](https://github.com/canadaduane/cleartouch/raw/main/screenshot.png)

YouTube Demo: https://youtu.be/Cpn_lILPhEM

NOTE: This project is part of the larger https://linuxtouchpad.org effort.

## Installation

Dependencies:

```
sudo apt install libglfw3-dev libxi-dev libxinerama-dev libxrandr-dev libxcursor-dev
```

With the [zig](https://ziglang.org/download/) compiler installed:

```
git clone https://github.com/canadaduane/cleartouch.git --recursive
zig build
cp ./zig-out/bin/cleartouch ./
```

Then run as root so you can grab the touchpad and read its input:

```
sudo ./cleartouch
```

## Hacking Docs

- [Linux Event Codes](https://github.com/torvalds/linux/blob/master/include/uapi/linux/input-event-codes.h)
- [Raylib Cheatsheet](https://www.raylib.com/cheatsheet/cheatsheet.html)
- [Pike](https://github.com/lithdew/pike)
