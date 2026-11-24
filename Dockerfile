# syntax=docker/dockerfile:1

##
## -- build
##

FROM golang:1.26.3-alpine3.23 AS build

ARG VERSION=0.7.0
ARG TARGETOS=linux
ARG TARGETARCH=amd64

WORKDIR /src

COPY go.mod go.sum ./
COPY vendor ./vendor
COPY cmd ./cmd
COPY pkg ./pkg

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -mod=vendor -trimpath \
      -ldflags "-s -w -X main.Version=${VERSION}" \
      -o /out/mtr-exporter ./cmd/mtr-exporter

##
## -- runtime
##

FROM alpine:3.23

RUN apk add --no-cache mtr tini \
    && apk del apk-tools libc-utils

COPY --from=build /out/mtr-exporter /usr/bin/mtr-exporter

EXPOSE 8080

# tini reaps mtr and mtr-packet child processes.
ENTRYPOINT ["/sbin/tini", "--", "/usr/bin/mtr-exporter"]
CMD ["--", "-n", "example.com"]
