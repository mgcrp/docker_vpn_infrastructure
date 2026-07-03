FROM golang:1.24-alpine AS builder

ARG MIERU_VERSION=v3.34.0

RUN apk add --no-cache git

RUN git clone --depth 1 --branch ${MIERU_VERSION} https://github.com/enfein/mieru.git /build
WORKDIR /build
ENV CGO_ENABLED=0
RUN GOOS=linux go build -trimpath -ldflags="-s -w" -o mita cmd/mita/mita.go

FROM alpine:3.21

RUN apk add --no-cache ca-certificates && \
    adduser -H -D -g "" mita && \
    mkdir -p /etc/mita /var/lib/mita /var/run/mita && \
    chown -R mita:mita /etc/mita /var/lib/mita /var/run/mita && \
    chmod 775 /etc/mita /var/lib/mita /var/run/mita

COPY --from=builder /build/mita /usr/local/bin/mita
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER mita

ENTRYPOINT ["/entrypoint.sh"]
