FROM rust:1-alpine AS builder

ARG TELEMT_VERSION=3.4.24

RUN apk add --no-cache git musl-dev

RUN git clone --depth 1 --branch ${TELEMT_VERSION} https://github.com/telemt/telemt.git /build
WORKDIR /build
RUN cargo build --release --locked

FROM alpine:3.21

RUN apk add --no-cache ca-certificates && \
    adduser -H -D -g "" telemt

COPY --from=builder /build/target/release/telemt /usr/local/bin/telemt

USER telemt

EXPOSE 443 9091

ENTRYPOINT ["/usr/local/bin/telemt"]
CMD ["run", "/etc/telemt.toml"]
