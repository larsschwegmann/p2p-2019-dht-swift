import Foundation
import SwiftCLI

let cli = CLI(singleCommand: DHTCommand())
cli.goAndExit()

