
############################################################
# build
############################################################
FROM ubuntu:24.04 AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates git make \
 && rm -rf /var/lib/apt/lists/*

COPY . /tmp/signaling
RUN cd /tmp/signaling && make
RUN cp /tmp/signaling/objs/signaling /usr/local/bin/signaling
RUN cp -R /tmp/signaling/www /usr/local/

############################################################
# dist
############################################################
FROM ubuntu:24.04 AS dist

# HTTP/1989
EXPOSE 1989
# SRS binary, config files and srs-console.
COPY --from=build /usr/local/bin/signaling /usr/local/bin/
COPY --from=build /usr/local/www /usr/local/www
# Default workdir and command.
WORKDIR /usr/local
CMD ["./bin/signaling"]
