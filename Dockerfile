FROM python:3.12-slim-bookworm as base
LABEL maintainer="Armin van der Togt <armin@vandertogt.org>"
LABEL Description="Image with ARM & RISC-V toolchain, cmake, python3 & clang-format"
WORKDIR /opt

# Install wget and bzip2 and xz to be able to download & unpack the compilers
RUN apt-get update && \
    apt-get install -y \
    wget \
    bzip2 \
    xz-utils \
    gnupg && \
    apt-get clean

# Add the llvm repo and update all packages
RUN wget -O /tmp/llvm.key https://apt.llvm.org/llvm-snapshot.gpg.key && apt-key add /tmp/llvm.key && \
    echo "\ndeb http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm-16 main\n" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

# Install version 16 of clangformat
RUN apt-get install -y \
    clang-format-16 && \
    cd /usr/bin && ln -s clang-format-16 clang-format && \
    apt-get clean

# # Install version 16 of llvm
# RUN apt-get install -y \
#     llvm-16 \
#     clang-16 && \
#     cd /usr/bin && \
#     ln -s clang-16 clang && ln -s clang-16 clang++ && \
#     apt-get clean

# Install libraries necessary for building embedded software
RUN apt-get install -y \
    build-essential \
    cmake \
    libbsd-dev \
    git \
    ninja-build && \
    apt-get clean

# For nanopb 
RUN apt-get install -y \
    protobuf-compiler \
    python3-protobuf \
    python3-pip \
    python3-intelhex \
    python3-virtualenv && \
    apt-get clean

# For GDB
RUN apt-get install -y \
    libsource-highlight-common \
    libsource-highlight4v5 && \
    apt-get clean


# for the version of gdb included with the gnu arm toolchain
RUN apt-get install -y \
libncurses5 \
libncursesw5 && \
apt-get clean

# For openocd
RUN apt-get install -y \
    libusb-1.0-0 \
    libhidapi-hidraw0 \
    libftdi1 && \
    apt-get clean

from base as builder
WORKDIR /build

# For building GDB
RUN apt-get install -y \
    ncurses-dev \
    texinfo \
    bison \
    flex \
    libgmp-dev \
    libmpfr-dev \
    libsource-highlight-dev

# For building openocd
RUN apt-get install -y \
    libtool \
    pkg-config \
    libusb-1.0-0-dev \
    libhidapi-dev \
    libftdi-dev

# Create a multiarch GDB
RUN wget -qO- https://ftp.gnu.org/gnu/gdb/gdb-14.2.tar.xz  | tar -xJ
RUN cd /build/gdb-14.2 && \
    ./configure --prefix=/opt/gdb-14.2 \
        --enable-targets=all \
        --enable-languages=all \
        --enable-multilib \
        --enable-interwork \
        --disable-nls && \
    make -j `nproc` && \
    make install

# compile openocd
RUN git clone https://git.code.sf.net/p/openocd/code openocd
RUN cd /build/openocd && \
    ./bootstrap && \
    ./configure --prefix=/opt/openocd && \
    make -j `nproc` && \
    make install

from base
COPY --from=builder /opt/gdb-14.2/ /opt/gdb-14.2
COPY --from=builder /opt/openocd/ /opt/openocd

WORKDIR /opt

# Download the toolchains from ARM
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 | tar -xj
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz | tar -xJ

# Download the toolchain for RISC-V
RUN wget -qO- https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v12.2.0-3/xpack-riscv-none-elf-gcc-12.2.0-3-linux-x64.tar.gz | tar -xz
#RUN wget -qO- https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz | tar -xz

# For git
RUN git config --global --add safe.directory '*'
