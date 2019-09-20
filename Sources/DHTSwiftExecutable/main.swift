import Foundation
import Logging
import HeliumLogger
import SwiftCLI
import DHTSwift
import NIO

HeliumLogger.bootstrapSwiftLog()

//let addr1 = try SocketAddress(ipAddress: "10.5.0.2", port: 7004)
//let addr2 = try SocketAddress(ipAddress: "10.5.0.3", port: 7004)
//let addr3 = try SocketAddress(ipAddress: "10.5.0.4", port: 7004)
//let addr4 = try SocketAddress(ipAddress: "10.5.0.5", port: 7004)
//
//let id1 = Identifier.socketAddress(address: addr1)
//let id2 = Identifier.socketAddress(address: addr2)
//let id3 = Identifier.socketAddress(address: addr3)
//let id4 = Identifier.socketAddress(address: addr4)
//
//print(id3.isBetween(lhs: id2, rhs: id1))


let cli = CLI(name: "DHTSwift", version: "1.0.0", commands: [DHTCommand(), APIClientCommand()])

cli.goAndExit()
