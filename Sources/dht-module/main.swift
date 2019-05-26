import Foundation
import SwiftCLI

class DHTCommand: Command {

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")

    func execute() throws {
        guard let configPath = configKey.value else {
            return
        }

        guard let config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }
        stdout <<< config.apiAddress
    }

    var name: String {
        return "dht-module"
    }

}

let cli = CLI(singleCommand: DHTCommand())
cli.goAndExit()

