import Foundation
import SwiftCLI
import DHTSwift

final class APIClientCommand: CommandGroup {

    var shortDescription: String = "Send a GET or PUT request to the DHT API server"
    let name = "api-client"

    let children: [Routable] = [APIClientGetCommand(), APIClientPutCommand()]
}

final class APIClientGetCommand: Command {
    let name = "get"

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")
    let key = Parameter()

    func execute() throws {
        stdout <<< String(key.value)

        guard let configPath = configKey.value else {
            stderr <<< "Error: You need to specify a config file with -c"
            return
        }

        guard let config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }

        stdout <<< config.apiAddress
        let apiClient = APICLient(address: config.apiAddress, port: config.apiPort)
        let getRequestMessage = apiClient.handleGet(with: key.value)
        do {
            try apiClient.start(payload: getRequestMessage)
        } catch let error {
            print("Error: \(error.localizedDescription)")
            apiClient.stop()
        }
    }
}

final class APIClientPutCommand: Command {
    let name = "put"

    let key = Parameter()
    let value = Parameter()

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")

    func execute() throws {
        stdout <<< String(key.value) + String(value.value)

        guard let configPath = configKey.value else {
            stderr <<< "Error: You need to specify a config file with -c"
            return
        }

        guard let config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }
        stdout <<< config.apiAddress

        let apiClient = APICLient(address: config.apiAddress, port: config.apiPort)
        let putRequestMessage = apiClient.handlePut(with: key.value, value: value.value)
        do {
            try apiClient.start(payload: putRequestMessage)
        } catch let error {
            print("Error: \(error.localizedDescription)")
            apiClient.stop()
        }
    }
}
