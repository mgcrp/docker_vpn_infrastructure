FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git

ENV GOTOOLCHAIN=auto

RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest && \
    xcaddy build --with github.com/caddyserver/forwardproxy=github.com/klzgrad/forwardproxy@naive \
        --output /caddy

FROM alpine:3.21

RUN apk add --no-cache ca-certificates

ENV XDG_DATA_HOME=/data
ENV XDG_CONFIG_HOME=/config

COPY --from=builder /caddy /usr/bin/caddy
COPY Caddyfile.tmpl /etc/caddy/Caddyfile.tmpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
