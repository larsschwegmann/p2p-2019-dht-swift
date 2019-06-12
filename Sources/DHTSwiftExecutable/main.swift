import Foundation
import SwiftCLI
import DHTSwift

let cli = CLI(name: "api")
cli.commands = [APIClientCommand()]

cli.goAndExit()
