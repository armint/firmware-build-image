FROM debian:bookworm-backports as base
LABEL maintainer="Armin van der Togt <armin@vandertogt.org>"
LABEL Description="Image with ARM & RISC-V toolchain, cmake, python3 & clang-format"
WORKDIR /opt

# Install wget and bzip2 and xz to be able to download the compilers
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
    apt-get upgrade && \
    apt-get clean

# Install version 16 of clangformat and llvm
RUN apt-get install -y \
    clang-format-16 \
    llvm-16 \
    clang-16 && \
    cd /usr/bin && ln -s clang-format-16 clang-format && ln -s clang-16 clang && ln -s clang-16 clang++ && \
    apt-get clean

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
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    apt-get clean

from base as builder
WORKDIR /build
RUN apt-get install -y \
    ncurses-dev \
    texinfo \
    bison \
    flex \
    libgmp-dev \
    libsource-highlight-dev
RUN wget -qO- https://ftp.gnu.org/gnu/gdb/gdb-12.1.tar.xz  | tar -xJ
RUN cd /build/gdb-12.1 && \
    ./configure --prefix=/opt/gdb-12.1 --target=arm-none-eabi && \
    make -j `nproc` && \
    make install

from base
COPY --from=builder /opt/gdb-12.1/ /opt/gdb-12.1

WORKDIR /opt
# for the version of gdb included with the gnu arm toolchain
RUN apt-get install -y \
      libncurses5 \
      libncursesw5 && \
      apt-get clean

# Download the toolchains from ARM
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 | tar -xj
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu/12.3.rel1/binrel/arm-gnu-toolchain-12.3.rel1-x86_64-arm-none-eabi.tar.xz | tar -xJ

# Download the toolchain for RISC-V
RUN wget -qO- https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v12.2.0-3/xpack-riscv-none-elf-gcc-12.2.0-3-linux-x64.tar.gz | tar -xz
#RUN wget -qO- https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v13.2.0-2/xpack-riscv-none-elf-gcc-13.2.0-2-linux-x64.tar.gz | tar -xz

# For git
RUN git config --global --add safe.directory '*'
