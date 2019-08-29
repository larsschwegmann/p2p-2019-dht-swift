# Build DHTWsiftExecutable in full fledged Swift image
FROM swift:5.0 as builder
WORKDIR /root
COPY . .
RUN swift build -c release


# Run DHTSwiftExecutable in slim Swift image
FROM swift:slim
WORKDIR /root
COPY --from=builder /root .

CMD ["sh", "-c", ".build/x86_64-unknown-linux/release/DHTSwiftExecutable dht-module -c docker_configs/node${NODEID}.conf.ini"]
