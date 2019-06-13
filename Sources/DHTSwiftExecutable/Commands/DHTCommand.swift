import Foundation
import SwiftCLI
import NIO
import DHTSwift

public class DHTCommand: Command {

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")

    public func execute() throws {
        guard let configPath = configKey.value else {
            stderr <<< "Error: You need to specify a config file with -c"
            return
        }

        guard let config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }

        // Create Event Loop Group for use in APIServer and P2PServer

        let apiServer = APIServer(config: config)
        let p2pServer = P2PServer(config: config)
        try apiServer.start().and(try p2pServer.start()).wait()
    }

    public var name: String {
        return "dht-module"
    }

}
