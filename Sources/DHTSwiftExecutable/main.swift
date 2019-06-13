import Foundation
import SwiftCLI
import DHTSwift

let cli = CLI(singleCommand: DHTCommand())

cli.goAndExit()
