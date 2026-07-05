FROM alpine:3.21 AS builder

ARG TROJAN_VERSION=v1.16.0

RUN apk add --no-cache git cmake make g++ boost-dev openssl-dev linux-headers

RUN git clone --depth 1 --branch ${TROJAN_VERSION} https://github.com/trojan-gfw/trojan.git /build
WORKDIR /build
RUN cmake -DENABLE_MYSQL=OFF . && \
    make -j"$(nproc)"

FROM alpine:3.21

RUN apk add --no-cache ca-certificates libstdc++ boost-system boost-program_options

COPY --from=builder /build/trojan /usr/local/bin/trojan
COPY config.json.tmpl /etc/trojan/config.json.tmpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 40443

ENTRYPOINT ["/entrypoint.sh"]
