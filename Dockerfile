FROM debian:bullseye
LABEL maintainer="Armin van der Togt <armin@vandertogt.org>"
LABEL Description="Image with ARM & RISC-V toolchain, cmake, python3 & clang-format"
WORKDIR /opt

# First install wget to be able to download the compilers
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    wget \
    bzip2 \
    gnupg
RUN wget -O /tmp/llvm.key https://apt.llvm.org/llvm-snapshot.gpg.key && apt-key add /tmp/llvm.key
RUN echo "\ndeb http://apt.llvm.org/bullseye/ llvm-toolchain-bullseye-15 main\n" >> /etc/apt/sources.list

# Update the system and install libraries necessary for building embedded software
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      build-essential \
      libbsd-dev \
      git \
      ninja-build \
      clang-format-15 \
      llvm-15 \
      clang-15 \
      protobuf-compiler \
      python3-protobuf \
      python3-pip \
      python3-intelhex \
      python3-virtualenv \
      xz-utils


RUN echo 'APT::Default-Release "bullseye";' > /etc/apt/apt.conf

RUN echo "\ndeb http://deb.debian.org/debian bullseye-backports main\n" >> /etc/apt/sources.list

RUN apt-get update && apt-get -t bullseye-backports install -y cmake && apt-get clean
RUN cd /usr/bin && ln -s clang-format-15 clang-format && ln -s clang-15 clang && ln -s clang-15 clang++
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1


# Download the toolchains from ARM
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu-rm/10.3-2021.10/gcc-arm-none-eabi-10.3-2021.10-x86_64-linux.tar.bz2 | tar -xj
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu/12.2.mpacbti-rel1/binrel/arm-gnu-toolchain-12.2.mpacbti-rel1-x86_64-arm-none-eabi.tar.xz | tar -xJ

# Download the toolchain for RISC-V
RUN wget -qO- https://github.com/xpack-dev-tools/riscv-none-elf-gcc-xpack/releases/download/v12.2.0-3/xpack-riscv-none-elf-gcc-12.2.0-3-linux-x64.tar.gz | tar -xz

# For git
RUN git config --global --add safe.directory '*'
