import Foundation
import Logging
import HeliumLogger
import SwiftCLI
import DHTSwift

HeliumLogger.bootstrapSwiftLog()

let cli = CLI(name: "DHTSwift", version: "1.0.0", commands: [DHTCommand(), APIClientCommand()])

cli.goAndExit()
