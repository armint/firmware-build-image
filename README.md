# firmware-builder

This repository contains the Dockerfile for a firmware build image.
The image contains the cross-compilers and tools to build and debug
firmware for ARM Cortex-M and RISC-V microcontrollers.

## Contents

The image uses `python:3.12-slim-trixie` (Debian trixie) as its base.

| Tool | Version | Location in the image |
|------|---------|-----------------------|
| Arm GNU Toolchain (`arm-none-eabi`) | 15.3.rel2 | `/opt/arm-gnu-toolchain-15.3.rel2-x86_64-arm-none-eabi` |
| xPack RISC-V GCC (`riscv-none-elf`) | 15.2.0-1 | `/opt/xpack-riscv-none-elf-gcc-15.2.0-1` |
| GDB, all targets | 15.2 | `/opt/gdb-15.2` |
| OpenOCD | commit `133dd9d` | `/opt/openocd` |
| Clang, LLVM, libc++, clang-format | 20 | `/usr/bin` |
| protoc (Protocol Buffers compiler) | 34.0 | `/usr/local/bin/protoc` |
| CMake, Ninja, Git, build-essential | Debian packages | `/usr/bin` |
| Python packages `protobuf`, `intelhex` | latest from PyPI | system Python |

The `bin` directories of the Arm and RISC-V toolchains are on the `PATH`.
GDB and OpenOCD are not on the `PATH`. Use the full path for these tools.

## Build the image

The `build.sh` script builds the image, adds the tags and pushes the image
to `docker.vandertogt.org/firmware-builder`. The `VERSION` variable in
`build.sh` sets the image tag.

```sh
./build.sh
```

To build the image without a push, use `docker build` directly:

```sh
docker build -t firmware-builder:local .
```

### Download cache

The build copies all files from the `download/` directory into the image
as a cache. The `get-and-unpack.sh` script uses a cached file if it is
available. If the file is not in the cache, the script downloads it.

The `download/` directory is in `.gitignore`. It must contain at least one
file, because the `COPY download/*` step fails on an empty directory.

## Use the image

Mount your project and run the build in the container:

```sh
docker run --rm -v "$PWD":/src -w /src docker.vandertogt.org/firmware-builder:v1.15.0 \
    arm-none-eabi-gcc --version
```

## Update a tool

1. Change the version in the `Dockerfile`. Toolchains use a download URL.
   GDB, LLVM, protobuf and OpenOCD use an `ARG`.
   For a toolchain, also change its directory in the `ENV PATH` line.
2. Increase `VERSION` in `build.sh`.
3. Update the table in this README.
