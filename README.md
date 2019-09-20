# DHTSwift

This project is an implementation of the DHT (Distributed Hash Table) module of the voidphone project for the TUM course "Peer to Peer Systems and Security" written in Swift. It is based on the Chord protocol and the implementation of the team from a previous year of the P2Psec course written in Rust. Please note that the Rust code from last year's course contains some errors such as not correctly stabilizing and handling peer failure and thus is not fully compatible with this codebase. However, the P2P protocol used in this implementation and the Rust implementation are basically identical, except for a few added messages for the successor list (see below).

This project was meant to have the same featureset as last year's Rust implementation. However, there are some added benefits:

- Peers leaving the network unexpectedly are handled through maintaining a successor list instead of a single successor per peer. However, the values assigned to the peers address space are lost if they did not happen to be replicated to another peer through modfiying the replication index.
- The TTL flag of a given DHTPut protocol message are properly respected, once the TTL is reached the DHT entry is purged from the network
- The project utilizes SwiftNIO for fast asynchronous I/O whereas the Rust implementation uses synchronous I/O operations / busy waiting

## Building

This project utilises Swift 5 and  the Swift Package Manager. It runs on both macOS and Linux (Linux support only tested through docker containers! using swift image based on ubuntu). 
In order to build the project in release mode, run `swift build -c release`.

## Running

In order to run the DHT module, execute `swift run -c release DHTSwiftExecutable dht-module -c <absolute_path_to_config_file>`.
In order to run the API Test client, execute `swift run -c release DHTSwiftExecutable api-client <arguments> [options]`.

Here's an example: To send a DHTPut with key `test` and value `hello_world` to a DHTSwiftModule intermodule API server running at `127.0.0.1:7003` run the following command:

`swift run -c release DHTSwiftExecutable api-client put test hello_world -i 127.0.0.1 -p 7003`

In order to send a DHTGet for key `test` to a DHTSwiftModule intermodule API Server running at `127.0.0.1:7003` run the following command:

`swift run -c release DHTSwiftExecutable api-client get test -i 127.0.0.1 -p 7003`

For available arguments and options, execute `swift run -c release DHTSwiftExecutable --help`.

For a sample config file, see `sample.config.ini`. We support all config options from last years Rust module. Additionally, we support a flag for specifying the maximum replication index to be looked up by the api module (default value is 4).

## Testing with Docker

We included a `docker-compose.yml` file which is configured to start 4 docker containers named `node1` to `node4` which are all running an instance of the application. We used this to test the stabilization algorithm and key distribution.
