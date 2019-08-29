FROM swift:5.0 as builder
WORKDIR /root
COPY . .
RUN swift build -c release

FROM swift:slim
WORKDIR /root
COPY --from=builder /root .
CMD [".build/x86_64-unknown-linux/release/DHTSwiftExecutable"]
