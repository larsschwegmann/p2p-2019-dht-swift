//
//  DHTCommand.swift
//  CNIOAtomics
//
//  Created by Lars Schwegmann on 11.06.19.
//

import Foundation
import SwiftCLI

class DHTCommand: Command {

    let configKey = Key<String>("-c", "--config", description: "Path to a custom config file")

    func execute() throws {
        guard let configPath = configKey.value else {
            stderr <<< "Error: You need to specify a config file with -c"
            return
        }

        guard let config = try Configuration(filePath: configPath) else {
            fatalError("Loading the config from the config file at \(configPath) failed")
        }
    }

    var name: String {
        return "dht-module"
    }

}
