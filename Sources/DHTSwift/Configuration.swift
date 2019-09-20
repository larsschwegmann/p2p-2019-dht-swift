import Foundation

public enum ConfigurationError: LocalizedError {
    case missingDHTConfigSection(filePath: String)
    case missingRequiredConfigKeyValuePair(key: String)
    case invalidINIFileFormat
    case invalidIPv4(String)
    case invalidIPv6(String)
    case invalidPort(String)

    public var errorDescription: String? {
        switch self {
        case .missingDHTConfigSection(let filePath):
            return "The Config Section for the DHT module is missing from config file at \(filePath)"
        case .missingRequiredConfigKeyValuePair(let key):
            return "The DHT config section is missing the following required key/value pair: \(key)"
        case .invalidINIFileFormat:
            return "The given configuration file is not a valid INI file"
        case .invalidIPv4(let addr):
            return "\(addr) is not a valid IPv4 address"
        case .invalidIPv6(let addr):
            return "\(addr) is not a valid IPv6 address"
        case .invalidPort(let addr):
            return "The specified port in \(addr) is not valid"
        }
    }
}

public struct Configuration {

    // MARK: Private ConfigKey struct

    private struct ConfigKey {
        static let dhtSection = "dht"

        static let apiAddress = "api_address"
        static let listenAddress = "listen_address"
        static let workerThreads = "worker_threads"
        static let timeout = "timeout"
        static let fingers = "fingers"
        static let stabilizationInterval = "stabilization_interval"
        static let bootstrapAddress = "bootstrap_address"
        static let maxReplicationIndex = "max_replication_index"
    }

    // MARK: Configuration Properties

    public var apiAddress: String
    public var apiPort: Int
    public var listenAddress: String
    public var listenPort: Int
    public var workerThreads: Int = 4
    public var timeout: Int = 300000
    public var fingers: Int = 128
    public var stabilizationInterval: Int = 30
    public var bootstrapAddress: String?
    public var bootstrapPort: Int?
    public var maxReplicationIndex: UInt8 = 4

    // MARK: Initializers

    public init?(filePath: String) throws {
        guard let configData = FileManager.default.contents(atPath: filePath),
            let configString = String(data: configData, encoding: .utf8) else {
            return nil
        }

        let configDict = try Configuration.buildDictionary(configContents: configString)

        guard let dhtConfig = configDict[ConfigKey.dhtSection] else {
            throw ConfigurationError.missingDHTConfigSection(filePath: filePath)
        }

        guard let apiAddressPort = dhtConfig[ConfigKey.apiAddress] else {
            throw ConfigurationError.missingRequiredConfigKeyValuePair(key: ConfigKey.apiAddress)
        }

        (self.apiAddress, self.apiPort) = try Configuration.parseInetAddress(apiAddressPort)

        guard let listenAddressPort = dhtConfig[ConfigKey.listenAddress] else {
            throw ConfigurationError.missingRequiredConfigKeyValuePair(key: ConfigKey.listenAddress)
        }

        (self.listenAddress, self.listenPort) = try Configuration.parseInetAddress(listenAddressPort)

        // Optional config parameters

        if let workerThreadsString = dhtConfig[ConfigKey.workerThreads],
            let workerThreads = Int(workerThreadsString) {
            self.workerThreads = workerThreads
        }

        if let timeoutString = dhtConfig[ConfigKey.timeout],
            let timeout = Int(timeoutString) {
            self.timeout = timeout
        }

        if let fingersString = dhtConfig[ConfigKey.fingers],
            let fingers = Int(fingersString) {
            self.fingers = fingers
        }

        if let stabilizationIntervalString = dhtConfig[ConfigKey.stabilizationInterval],
            let stabilizationInterval = Int(stabilizationIntervalString) {
            self.stabilizationInterval = stabilizationInterval
        }

        if let bootstrapAddressString = dhtConfig[ConfigKey.bootstrapAddress] {
            let (bootstrapAddress, bootstrapPort) = try Configuration.parseInetAddress(bootstrapAddressString)
            self.bootstrapAddress = bootstrapAddress
            self.bootstrapPort = bootstrapPort
        }

        if let maxReplicationString = dhtConfig[ConfigKey.maxReplicationIndex],
            let maxReplication = UInt8(maxReplicationString) {
            self.maxReplicationIndex = maxReplication
        }
    }

    // MARK: Static Function

    private static func parseInetAddress(_ inetAddr: String) throws -> (String, Int) {
        let bracketPattern = #"\[(.*?)\]"#
        let bracketRange = inetAddr.range(of: bracketPattern, options: .regularExpression)
        if let bracketRange = bracketRange {
            // IPv6
            var ip = String(inetAddr[bracketRange])
            ip.removeFirst()
            ip.removeLast()
            // Taken from https://www.regextester.com/96774
            let ipv6Pattern = #"^(?:(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){6})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:::(?:(?:(?:[0-9a-fA-F]{1,4})):){5})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){4})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,1}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){3})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,2}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:(?:[0-9a-fA-F]{1,4})):){2})(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,3}(?:(?:[0-9a-fA-F]{1,4})))?::(?:(?:[0-9a-fA-F]{1,4})):)(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,4}(?:(?:[0-9a-fA-F]{1,4})))?::)(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9]))\.){3}(?:(?:25[0-5]|(?:[1-9]|1[0-9]|2[0-4])?[0-9])))))))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,5}(?:(?:[0-9a-fA-F]{1,4})))?::)(?:(?:[0-9a-fA-F]{1,4})))|(?:(?:(?:(?:(?:(?:[0-9a-fA-F]{1,4})):){0,6}(?:(?:[0-9a-fA-F]{1,4})))?::))))$"#
            guard ip.range(of: ipv6Pattern, options: .regularExpression) != nil else {
                throw ConfigurationError.invalidIPv6(ip)
            }
            guard let port = Int(String(inetAddr[bracketRange.upperBound...].filter({ $0 != ":" }))) else {
                throw ConfigurationError.invalidPort(inetAddr)
            }
            return (ip, port)
        } else {
            // IPv4
            let ip = String(inetAddr.split(separator: ":")[0])
            let ipv4Pattern = #"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"#
            guard ip.range(of: ipv4Pattern, options: .regularExpression) != nil else {
                throw ConfigurationError.invalidIPv4(ip)
            }
            guard let port = Int(String(inetAddr.split(separator: ":")[1])) else {
                throw ConfigurationError.invalidPort(inetAddr)
            }
            return (ip, port)
        }
    }

    private static func buildDictionary(configContents: String) throws -> [String: [String: String]] {
        var dict = [String: [String: String]]()
        let lines = configContents.split(separator: "\n")

        var currentSection = [String: String]()
        var currentSectionName: String?

        for line in lines {
            if line.first == "[" && line.last == "]" {
                // Section header
                var sectionName = line
                sectionName.removeFirst()
                sectionName.removeLast()
                currentSectionName = String(sectionName)
                currentSection = [String: String]()
                dict[String(sectionName)] = currentSection
            } else {
                // Key value pair
                let items = line.split(separator: "=")
                let key = String(items[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                let value = String(items[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                currentSection[key] = value
                guard let sectionName = currentSectionName else {
                    throw ConfigurationError.invalidINIFileFormat
                }
                dict[sectionName] = currentSection
            }
        }
        return dict
    }
}
