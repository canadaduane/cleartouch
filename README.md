# Cleartouch

A graphical visualization of your Linux touchpad device's input.

Cleartouch grabs your `/dev/input*` data stream and interprets the kernel multitouch events so they can be represented visually on a 2d canvas (via raylib).

<img src="https://github.com/canadaduane/cleartouch/raw/main/screenshot.png" width="600" height="400">

## Installation

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

