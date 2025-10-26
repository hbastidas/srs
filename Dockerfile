ARG ARCH
ARG IMAGE=ubuntu:24.04
ARG DIST_IMAGE=ubuntu:24.04
FROM ${ARCH}${IMAGE} AS build

ARG CONFARGS
ARG MAKEARGS
ARG INSTALLDEPENDS
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG SRS_AUTO_PACKAGER
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM, PACKAGER: ${#SRS_AUTO_PACKAGER}, CONFARGS: ${CONFARGS}, MAKEARGS: ${MAKEARGS}, INSTALLDEPENDS: ${INSTALLDEPENDS}"

# https://serverfault.com/questions/949991/how-to-install-tzdata-on-a-ubuntu-docker-image
ENV DEBIAN_FRONTEND=noninteractive

# To use if in RUN, see https://github.com/moby/moby/issues/7281#issuecomment-389440503
# Note that only exists issue like "/bin/sh: 1: [[: not found" for Ubuntu20, no such problem in CentOS7.
SHELL ["/bin/bash", "-c"]

# Install depends tools.
RUN if [[ $INSTALLDEPENDS != 'NO' ]]; then \
        apt-get update && apt-get install -y gcc make g++ patch unzip xz-utils perl git libasan5 automake pkg-config cmake tclsh nasm yasm wget ca-certificates libssl-dev; \
    fi

# Copy source code to docker.
COPY . /srs
WORKDIR /srs/trunk

# Build and install SRS.
# Note that SRT is enabled by default, so we configure without --srt=on.
# Note that we have copied all files by make install.
RUN ./configure ${CONFARGS} && make ${MAKEARGS} && make install

############################################################
# dist
############################################################
FROM ${DIST_IMAGE} AS dist

ARG BUILDPLATFORM
ARG TARGETPLATFORM
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM"

# Expose ports for streaming @see https://github.com/ossrs/srs#ports
EXPOSE 1935 1985 8080 5060 9000 8000/udp 10080/udp

# FFMPEG binary produced during build is placed under /srs/trunk/objs/ffmpeg/bin/ffmpeg
COPY --from=build /srs/trunk/objs/ffmpeg/bin/ffmpeg /usr/local/srs/objs/ffmpeg/bin/ffmpeg
# SRS binary, config files and srs-console.
COPY --from=build /usr/local/srs /usr/local/srs

# Ensure container has NVIDIA capabilities by default.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=video,compute,utility



# Test the version of binaries.
RUN ldd /usr/local/srs/objs/ffmpeg/bin/ffmpeg && \
    /usr/local/srs/objs/ffmpeg/bin/ffmpeg -version && \
    ldd /usr/local/srs/objs/srs

# Default workdir and command.
WORKDIR /usr/local/srs
ENV SRS_DAEMON=off SRS_IN_DOCKER=on
CMD ["./objs/srs", "-c", "conf/docker.conf"]

