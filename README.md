# DHTSwift

This project is an implementation of the DHT (Distributed Hash Table) module of the voidphone project for the TUM course "Peer to Peer Systems and Security" written in Swift. 

## Building

This proiject utilises Swift 5 and  the Swift Package manager. It should run on both macOS and Linux. 
In order to build the project in release mode, run `swift build -c release`.

## Running

In order to run the DHT module, execute `swift run DHTSwiftExecutable dht-module [options]`.
In order to run the API Test client, execute `swift run DHTSwiftExecutable api-client <argumetns> [options]`.
For available arguments and options, execute `swift run DHTSwiftExecutable --help`.
