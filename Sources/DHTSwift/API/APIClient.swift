import Foundation
import Logging
import NIO

// MARK: - APIClient

public final class APICLient {

    // MARK: Properties

    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    let address: String
    let port: Int
    let maxReplication: UInt8

    private let logger = Logger(label: "APIClient")

    // MARK: Initializers

    public init(address: String, port: Int, maxReplication: UInt8) {
        self.address = address
        self.port = port
        self.maxReplication = maxReplication
    }

    // MARK: Public functions

    public func start(payload: [UInt8]) throws {
        let requestPayload = payload

        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(APIClientHandler(requestPayload: requestPayload))
        }

        do {
            let channel = try bootstrap.connect(host: address, port: port).wait()
            print("Connected to host with ip \(address) on port \(port)")
            let addr = try? SocketAddress(ipAddress: address, port: port)
            logger.info("Connected to \(addr?.description ?? "nil")")
            try channel.closeFuture.wait()
        } catch let error {
            throw error
        }
    }

    public func stop() {
        do {
            try group.syncShutdownGracefully()
        } catch let error {
            logger.error("Error shutting down \(error.localizedDescription)")
            exit(0)
        }
        logger.info("Client connection closed")
    }

    // MARK: - handleGet
    public func handleGet(with key: String) -> [UInt8] {
        let dhtGet = DHTGet(key: key.toByteArray(cut: 32))
        return dhtGet.getBytes()
    }

    // MARK: - handlePut
    public func handlePut(with key: String, value: String) -> [UInt8] {
        let dhtPut = DHTPut(ttl: 60, replication: UInt8(self.maxReplication), key: key.toByteArray(cut: 32), value: value.toByteArray(cut: value.utf8.count))
        return dhtPut.getBytes()
    }
}
