# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM golang:alpine AS build
ARG TARGETOS
ARG TARGETARCH
WORKDIR /app
COPY . ./
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o headerer ./cmd/main.go

FROM alpine
LABEL authors="zerotay"
COPY --from=build /app/headerer /headerer
ENTRYPOINT ["/headerer"]