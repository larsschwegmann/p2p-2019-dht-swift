import Foundation
import SwiftCLI
import DHTSwift

let cli = CLI(name: "DHTSwift", version: "1.0.0", commands: [DHTCommand(), APIClientCommand()])

cli.goAndExit()
