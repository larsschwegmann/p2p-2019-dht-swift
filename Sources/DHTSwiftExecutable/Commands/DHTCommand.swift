import Foundation
import SwiftCLI
import NIO
import NIOExtras
import DHTSwift

public class DHTCommand: Command {

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")
    let bootstrapKey = Key<String>("-b", "--bootstrap", description: "IP of bootstrap peer")
    let bootstrapPortKey = Key<Int>("-p", "--port", description: "port of bootstrap peer")

    public func execute() throws {
        guard let configPath = configKey.value else {
            stderr <<< "Error: You need to specify a config file with -c"
            return
        }

        guard let config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }

        // Create Event Loop Group for use in APIServer and P2PServer
        Chord.configuration = config
        if let ip = bootstrapKey.value, let port = bootstrapPortKey.value {
            try Chord.shared.bootstrap(bootstrapAddress: SocketAddress.init(ipAddress: ip, port: port)).wait()
            let apiServer = APIServer(config: config)
            let p2pServer = P2PServer(config: config)
            (_,_) = try apiServer.start().and(try p2pServer.start()).wait()
        } else {
            Chord.shared.bootstrap()
            let apiServer = APIServer(config: config)
            let p2pServer = P2PServer(config: config)
            (_, _) = try apiServer.start().and(try p2pServer.start()).wait()
        }

    }

    public var name: String {
        return "dht-module"
    }

    public let shortDescription: String = "Runs the DHT Module component of the voidphone project"

}
