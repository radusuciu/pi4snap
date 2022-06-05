FROM rust:1.61-slim-buster as librespot

ARG LIBRESPOT_VERSION=0.4.1

RUN apt-get update \
    && apt-get -y install build-essential libasound2-dev portaudio19-dev curl unzip \
    && apt-get clean && rm -fR /var/lib/apt/lists
RUN cargo install librespot --version "${LIBRESPOT_VERSION}"

FROM ubuntu:20.04 AS snapcast-build

ARG DEBIAN_FRONTEND=noninteractive
ARG SNAPCAST_VERSION=0.26.0
ARG SNAPWEB_VERSION=0.2.0
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
RUN cmake --build build --parallel 4
RUN fakeroot make -j 4 -f debian/rules CMAKEFLAGS="-DBOOST_ROOT=boost_${BOOST_MAJOR}_${BOOST_MINOR}_0 -DCMAKE_CXX_COMPILER_LAUNCHER=ccache" binary
RUN dpkg -i /snapserver_${SNAPCAST_VERSION}-*.deb

RUN wget https://github.com/badaix/snapweb/archive/refs/tags/v${SNAPWEB_VERSION}.zip \
    && unzip v${SNAPWEB_VERSION}.zip \
    && mv snapweb-${SNAPWEB_VERSION} snapweb

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
        alsa-utils \
        expat \
    && apt-get clean && rm -fR /var/lib/apt/lists

WORKDIR /snapcast

COPY --from=librespot /usr/local/cargo/bin/librespot /usr/local/bin/
COPY --from=snapcast-build /snapcast/bin/snapserver /usr/local/bin/
COPY --from=snapcast-build /etc/snapserver.conf /etc/
COPY --from=snapcast-build /snapcast/snapweb /usr/share/snapserver/snapweb
COPY run.sh .

EXPOSE 1704 1705 1780
CMD [ "/snapcast/run.sh" ]
