FROM rust:1.61-slim-buster as librespot
ARG LIBRESPOT_VERSION=0.4.1
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get -y install \
        build-essential \
        libasound2-dev \
        portaudio19-dev \
        libavahi-compat-libdnssd-dev \
        curl \
        unzip \
    && apt-get clean && rm -fR /var/lib/apt/lists
RUN cargo install librespot --version "${LIBRESPOT_VERSION}" --features with-dns-sd

FROM ubuntu:20.04 AS snapcast-build
ARG DEBIAN_FRONTEND=noninteractive
ARG SNAPCAST_VERSION=0.26.0
ARG BOOST_MAJOR=1
ARG BOOST_MINOR=78
ENV TZ=America/Los_Angeles
RUN apt-get update \
    && apt-get install -y \
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
        cmake \
        unzip \
    && apt-get clean && rm -fR /var/lib/apt/lists
RUN git clone --depth=1 --branch v${SNAPCAST_VERSION} https://github.com/badaix/snapcast.git \
    && cd snapcast \
    && git submodule update --init --recursive
WORKDIR /snapcast
RUN wget https://boostorg.jfrog.io/artifactory/main/release/${BOOST_MAJOR}.${BOOST_MINOR}.0/source/boost_${BOOST_MAJOR}_${BOOST_MINOR}_0.tar.bz2 \
    && tar xjf boost_${BOOST_MAJOR}_${BOOST_MINOR}_0.tar.bz2
RUN cmake -S . -B build -DBOOST_ROOT=boost_${BOOST_MAJOR}_${BOOST_MINOR}_0 -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_FLAGS="$CXXFLAGS -Werror -Wall -Wextra -pedantic -Wno-unused-function"
RUN cmake --build build --parallel 20

FROM node:18.2-bullseye-slim as snapweb-build
ARG DEBIAN_FRONTEND=noninteractive
ARG SNAPWEB_VERSION=0.2.0
RUN apt-get update \
    && apt-get install -y \
        build-essential \
        git \
    && apt-get clean && rm -fR /var/lib/apt/lists
RUN npm install -g typescript
WORKDIR /build
RUN git clone --depth=1 https://github.com/badaix/snapweb.git
WORKDIR /build/snapweb
RUN npm install --save @types/wicg-mediasession@1.1.0
RUN make

FROM ubuntu:20.04 AS snapserver
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
RUN apt-get update \
    && apt-get install -y \
        libportaudio2 \
        libvorbis0a \
        libavahi-client3 \
        libflac8 \
        libvorbisenc2 \
        libvorbisfile3 \
        libopus0 \
        libsoxr0 \
        avahi-daemon \
        libavahi-compat-libdnssd1 \
        alsa-utils \
        expat \
    && apt-get clean && rm -fR /var/lib/apt/lists
WORKDIR /snapcast
COPY --from=librespot /usr/local/cargo/bin/librespot /usr/local/bin/
COPY --from=snapcast-build /snapcast/bin/snapserver /usr/local/bin/
COPY --from=snapcast-build /snapcast/server/etc/snapserver.conf /etc/
COPY --from=snapweb-build /build/snapweb/dist /usr/share/snapserver/snapweb
COPY run.sh .

EXPOSE 1704 1705 1780
CMD [ "/snapcast/run.sh" ]
