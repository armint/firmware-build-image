FROM python:3.12-slim-trixie AS base
LABEL maintainer="Armin van der Togt <armin@vandertogt.org>"
LABEL Description="Image with ARM & RISC-V toolchain, cmake, python3 & clang-format"
ARG LLVM_VERSION=20
ARG GDB_VERSION=15.2
# Some known working tag ; change at your own risk!
ARG OPENOCD_TAG=133dd9d669e5b8beb7c7787b0be677621808e72d
WORKDIR /opt

# Install wget and bzip2 and xz to be able to download & unpack the compilers
RUN apt-get update && \
    apt-get install -y \
    wget \
    bzip2 \
    xz-utils \
    gnupg \
    nodejs && \
    apt-get clean

# Add the llvm repo and update all packages
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc && \
    echo "deb http://apt.llvm.org/trixie/ llvm-toolchain-trixie-$LLVM_VERSION main\n" >> /etc/apt/sources.list.d/llvm.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

# Install clangformat
RUN apt-get install -y \
    clang-format-$LLVM_VERSION && \
    cd /usr/bin && ln -s clang-format-$LLVM_VERSION clang-format && \
    apt-get clean


# Install version $LLVM_VERSION of llvm
RUN apt-get install -y \
    llvm-$LLVM_VERSION \
    libc++-$LLVM_VERSION-dev \
    libc++abi-$LLVM_VERSION-dev \
    clang-$LLVM_VERSION && \
    cd /usr/bin && \
    ln -s clang-$LLVM_VERSION clang && ln -s clang-$LLVM_VERSION clang++ && \
    apt-get clean

# Install libraries necessary for building embedded software
RUN apt-get install -y \
    build-essential \
    cmake \
    libbsd-dev \
    git \
    ninja-build && \
    apt-get clean

# Install protobuf (from official release for editions support) and nanopb
ARG PROTOBUF_VERSION=34.0
RUN wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/protoc-${PROTOBUF_VERSION}-linux-x86_64.zip -O /tmp/protoc.zip && \
    apt-get install -y unzip && \
    unzip -o /tmp/protoc.zip -d /usr/local bin/protoc 'include/*' && \
    rm /tmp/protoc.zip && \
    apt-get install -y \
    python3-pip \
    python3-virtualenv && \
    pip install --break-system-packages protobuf intelhex && \
    apt-get clean

# For GDB
RUN apt-get install -y \
    libsource-highlight-common \
    libsource-highlight4v5 && \
    apt-get clean

# For openocd
RUN apt-get install -y \
    libusb-1.0-0 \
    libhidapi-hidraw0 \
    libftdi1 && \
    apt-get clean

FROM base AS builder
ADD get-and-unpack.sh /usr/local/bin
RUN chmod +x /usr/local/bin/get-and-unpack.sh
RUN mkdir -p /packages
COPY download/* /packages

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

WORKDIR /build

# Get the GDB source files
RUN get-and-unpack.sh https://ftp.gnu.org/gnu/gdb/gdb-$GDB_VERSION.tar.xz

# Create a multiarch GDB
RUN cd /build/gdb-$GDB_VERSION && \
    ./configure --prefix=/opt/gdb-$GDB_VERSION \
        --enable-targets=all \
        --enable-languages=all \
        --enable-multilib \
        --enable-interwork \
        --disable-nls && \
    make -j && \
    make install

# Clone openocd
RUN git clone --recurse-submodules https://git.code.sf.net/p/openocd/code openocd

# compile openocd
RUN cd /build/openocd && \
    git checkout $OPENOCD_TAG && \
    ./bootstrap && \
    ./configure --prefix=/opt/openocd && \
    make -j && \
    make install

# Get all the toolchains
WORKDIR /unpack
RUN get-and-unpack.sh https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/packages/generic/gnu-toolchain/15.3.rel2/arm-gnu-toolchain-15.3.rel2-x86_64-arm-none-eabi.tar.xz

RUN get-and-unpack.sh https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v15.2.0-1/xpack-riscv-none-elf-gcc-15.2.0-1-linux-x64.tar.gz



FROM base
COPY --from=builder /opt /opt
COPY --from=builder /unpack /opt
ENV PATH="/opt/arm-gnu-toolchain-15.3.rel2-x86_64-arm-none-eabi/bin:/opt/xpack-riscv-none-elf-gcc-15.2.0-1/bin:/opt/gdb-${GDB_VERSION}/bin:/opt/openocd/bin:${PATH}"

# For git
RUN git config --global --add safe.directory '*'
