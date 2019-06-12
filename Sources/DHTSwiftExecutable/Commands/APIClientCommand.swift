//
//  APIClientCommand.swift
//  dht-module
//
//  Created by Dimitri Tyan on 11.06.19.
//

import Foundation
import SwiftCLI
import DHTSwift

class APIClientCommand: CommandGroup {

    var shortDescription: String = "Send a GET or PUT request to the DHT API server"
    let name = "api"

    let children: [Routable] = [APIClientGetCommand(), APIClientPutCommand()]

    // func execute() throws {    }
}

class APIClientGetCommand: Command {
    let name = "get"

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")
    let key = Parameter()

    // let apiClient = APICLient(apiAddress: )
    func execute() throws {
        stdout <<< String(key.value)
        // TODO
        // Send a get request to the API server
        guard let configPath = configKey.value else {
            stderr <<< "Error: You need to specify a config file with -c"
            return
        }

        guard let config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }
        stdout <<< config.apiAddress
        let apiClient = APICLient(address: config.apiAddress, port: config.apiPort)
        apiClient.handleGet(with: key.value)
    }
}

class APIClientPutCommand: Command {
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
        apiClient.handlePut(with: key.value, value: value.value)
    }
}
