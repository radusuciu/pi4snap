FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
RUN apt-get update && apt-get install -y \
    git \
    ca-certificates \
    libasound2-dev \
    libvorbisidec-dev \
    libvorbis-dev \
    libopus-dev \
    libflac-dev \
    libsoxr-dev \
    alsa-utils \
    libavahi-client-dev \
    avahi-daemon \
    libexpat1-dev \
    build-essential \
    wget \
    ccache \
    expat \
    debhelper \
    cmake

RUN git clone --depth=1 --branch v0.23.0 https://github.com/badaix/snapcast.git && cd snapcast && git submodule update --init --recursive

WORKDIR /snapcast

RUN wget https://dl.bintray.com/boostorg/release/1.75.0/source/boost_1_75_0.tar.bz2 && tar xjf boost_1_75_0.tar.bz2
RUN cmake -S . -B build -DBOOST_ROOT=boost_1_75_0 -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_FLAGS="$CXXFLAGS -Werror -Wall -Wextra -pedantic -Wno-unused-function"
RUN cmake --build build
RUN fakeroot make -f debian/rules CMAKEFLAGS="-DBOOST_ROOT=boost_1_75_0 -DCMAKE_CXX_COMPILER_LAUNCHER=ccache" binary
RUN dpkg -i /snapserver_0.23.0-1_arm64.deb

EXPOSE 1704 1705 1780
ENTRYPOINT ["/bin/bash","-c","/usr/bin/snapserver"]
