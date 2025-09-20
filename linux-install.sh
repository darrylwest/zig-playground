#!/usr/bin/env bash
# dpw@alamo
# 2025-09-20 15:37:29
#

set -eu

export ZIG_VERSION=$(curl -s "https://api.github.com/repos/ziglang/zig/releases/latest" | grep -Po '"tag_name": "\K[0-9.]+')

wget -qO zig.tar.xz https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz

sudo mkdir /opt/zig
sudo tar xf zig.tar.xz --strip-components=1 -C /opt/zig

sudo ln -s /opt/zig/zig /usr/local/bin/zig

echo "Zig ${ZIG_VERSION} installed..."

zig version
