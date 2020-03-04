FROM alpine:edge as build

WORKDIR /build
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    && apk update && apk upgrade \
    && apk --no-cache add coreutils git build-base cmake openssl-dev libuv-dev hwloc-dev \
    && git clone https://github.com/xmrig/xmrig

WORKDIR /build/xmrig
RUN sed -i 's/kDefaultDonateLevel = 5/kDefaultDonateLevel = 0/' src/donate.h \
    && sed -i 's/kMinimumDonateLevel = 1/kMinimumDonateLevel = 0/' src/donate.h \
    && cmake -DCMAKE_BUILD_TYPE=Release . \
    && make -j$(getconf _NPROCESSORS_ONLN)

#---------------------------------------------------------------------
FROM alpine:edge

RUN echo 'http://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories \
    && apk update && apk upgrade \
    && apk --no-cache add coreutils libssl1.1 libuv hwloc sudo \
    && addgroup -S docker && adduser -S -D -h /xmrig -G docker docker

COPY --from=build /build/xmrig/xmrig /usr/bin

USER docker
WORKDIR /xmrig
ADD config.json config.json
RUN /usr/bin/xmrig -c config.json
ENTRYPOINT ["/bin/nice", "-n19", "/usr/bin/xmrig"]
