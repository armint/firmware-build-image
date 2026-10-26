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

The `bin` directories of the Arm and RISC-V toolchains, GDB and OpenOCD
are on the `PATH`.

## Build the image

The git tag on the current commit sets the image version, for example
`v1.15.0`. The repository has no other version number.

The `build.sh` script builds the image locally and pushes it to
`docker.vandertogt.org/firmware-builder`. The script stops with an error if
the current commit has no tag, or if the working tree has changes that are
not committed.

```sh
git tag v1.15.0
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

The files in `download/` are in `.gitignore`. Git keeps only
`download/.gitkeep`, so the directory is always available. An empty cache is
valid: the build then downloads all files.

### GitHub Actions

The `.github/workflows/docker.yml` workflow builds the image on GitHub for
each branch push and for each pull request. These builds only
check that the image builds.

When you push a tag that starts with `v`, the workflow also publishes the
image to the GitHub Container Registry (GHCR) with two tags:

- `ghcr.io/armint/firmware-build-image:<tag>`
- `ghcr.io/armint/firmware-build-image:latest`

GHCR makes a new package private. After the first publish, open the package
settings on GitHub and set the visibility to public. Do this one time only.

The repository is on GitLab and on GitHub
(https://github.com/armint/firmware-build-image). Merge requests use GitLab.
Push the branches and tags to the `github` remote too, so that GitHub builds
them. To add the remote, run this command one time:

```sh
git remote add github https://github.com/armint/firmware-build-image.git
```

To publish a release, push the tag to GitHub:

```sh
git tag v1.15.0
git push github v1.15.0
```

## Use the image

Mount your project and run the build in the container:

```sh
docker run --rm -v "$PWD":/src -w /src ghcr.io/armint/firmware-build-image:latest \
    arm-none-eabi-gcc --version
```

## Update a tool

1. Change the version in the `Dockerfile`. Toolchains use a download URL.
   GDB, LLVM, protobuf and OpenOCD use an `ARG`.
   For a toolchain, also change its directory in the `ENV PATH` line.
2. Update the table in this README.
3. After the merge, tag the merge commit with the next version.

## License

The files in this repository use the MIT license. See [LICENSE](LICENSE).
The tools in the image use their own licenses. For example, GCC and GDB
use the GNU General Public License (GPL).
