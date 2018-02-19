FROM golang:alpine as build
WORKDIR /go/src/github.com/scottrigby/codefresh-pr
ADD . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main . && cp main /tmp/

FROM scratch
COPY --from=build /tmp/main .
EXPOSE 3000
CMD ["./main"]
