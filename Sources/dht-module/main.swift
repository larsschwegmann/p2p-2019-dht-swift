import Foundation

guard CommandLine.arguments.count >= 3, CommandLine.arguments[1] == "-c" else {
    print("Unexpected arguments. Usage: dht-module -c <path to config>")
    exit(1)
}

let configPath = CommandLine.arguments[2]
guard let config = Configuration(filePath: configPath) else {
    fatalError("Loading the config from the config file at \(configPath) failed")
}

