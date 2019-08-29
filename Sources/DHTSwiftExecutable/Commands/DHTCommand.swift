import Foundation
import SwiftCLI
import NIO
import NIOExtras
import DHTSwift

public final class DHTCommand: Command {

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")
    let bootstrapKey = Key<String>("-b", "--bootstrap", description: "IP of bootstrap peer")
    let bootstrapPortKey = Key<Int>("-p", "--port", description: "port of bootstrap peer")

    public func execute() throws {
        guard let configPath = configKey.value else {
            stderr <<< "Error: You need to specify a config file with -c"
            return
        }

        guard var config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }
        
        if let ip = bootstrapKey.value, let port = bootstrapPortKey.value {
            config.bootstrapAddress = ip
            config.bootstrapPort = port
        }

        let chord = Chord(config: config)

        let apiServer = APIServer(config: config, chord: chord)
        let p2pServer = P2PServer(config: config, chord: chord)

        let apiCloseFuture =  try apiServer.start()
        let p2pCloseFuture = try p2pServer.start()

        try chord.bootstrap().wait() // Move this behind the api/p2p server.start()

        (_, _) = try apiCloseFuture.and(p2pCloseFuture).wait()

    }

    public var name: String {
        return "dht-module"
    }

    public let shortDescription: String = "Runs the DHT Module component of the voidphone project"

}
