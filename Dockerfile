# Multi-stage build for tippecanoe with PMTiles streaming support

FROM debian:bookworm AS build

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    build-essential make g++ \
    libsqlite3-dev zlib1g-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . /src

# Clean any existing build artifacts and build all binaries
RUN make clean && make -j"$(nproc)"

FROM debian:bookworm-slim AS runtime
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libsqlite3-0 zlib1g \
 && rm -rf /var/lib/apt/lists/*

# Install binaries in default PATH
COPY --from=build /src/tippecanoe /usr/local/bin/tippecanoe
COPY --from=build /src/tippecanoe-decode /usr/local/bin/tippecanoe-decode
COPY --from=build /src/tile-join /usr/local/bin/tile-join
COPY --from=build /src/tippecanoe-enumerate /usr/local/bin/tippecanoe-enumerate
COPY --from=build /src/tippecanoe-json-tool /usr/local/bin/tippecanoe-json-tool
COPY --from=build /src/tippecanoe-overzoom /usr/local/bin/tippecanoe-overzoom

# Also place copies under /opt/tippecanoe so downstream images can pin exact binaries
RUN mkdir -p /opt/tippecanoe && \
    cp /usr/local/bin/tippecanoe /opt/tippecanoe/tippecanoe && \
    cp /usr/local/bin/tile-join /opt/tippecanoe/tile-join && \
    cp /usr/local/bin/tippecanoe-decode /opt/tippecanoe/tippecanoe-decode && \
    cp /usr/local/bin/tippecanoe-enumerate /opt/tippecanoe/tippecanoe-enumerate && \
    cp /usr/local/bin/tippecanoe-json-tool /opt/tippecanoe/tippecanoe-json-tool && \
    cp /usr/local/bin/tippecanoe-overzoom /opt/tippecanoe/tippecanoe-overzoom

# When used standalone, default to tippecanoe help
# When used as base image, this will be overridden
CMD ["/usr/local/bin/tippecanoe", "--help"]