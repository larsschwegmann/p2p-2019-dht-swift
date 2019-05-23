import Foundation

struct Configuration {

    // MARK: Private ConfigKey struct

    private struct ConfigKey {
        static let dhtSection = "dht"
        static let apiAddress = "api_address"
    }

    // MARK: COnfiguration Properties

    var apiAddress: String
    var apiPort: Int

    // MARK: Initializers

    init?(filePath: String) {
        guard let configData = FileManager.default.contents(atPath: filePath),
            let configString = String(data: configData, encoding: .utf8) else {
            return nil
        }

        let configDict = Configuration.buildDictionary(configContents: configString)

        guard let dhtConfig = configDict[ConfigKey.dhtSection] else {
            fatalError("Config Section for the DHT module is missing from config file at \(filePath)")
        }

        guard let apiAddressPort = dhtConfig[ConfigKey.apiAddress] else {
            fatalError("[DHT] config section has no \(ConfigKey.apiAddress) key/value pair")
        }

        (self.apiAddress, self.apiPort) = Configuration.parseInetAddress(apiAddressPort)
    }

    // MARK: Static Function

    private static func parseInetAddress(_ inetAddr: String) -> (String, Int) {
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
                fatalError("\(ip) is not a valid IPv6 address")
            }
            guard let port = Int(String(inetAddr[bracketRange.upperBound...].filter({ $0 != ":" }))) else {
                fatalError("Invalid port in \(inetAddr)")
            }
            return (ip, port)
        } else {
            // IPv4
            let ip = String(inetAddr.split(separator: ":")[0])
            let ipv4Pattern = #"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$"#
            guard ip.range(of: ipv4Pattern, options: .regularExpression) != nil else {
                fatalError("\(ip) is not a valid IPv4 address")
            }
            guard let port = Int(String(inetAddr.split(separator: ":")[1])) else {
                fatalError("Invalid port in \(inetAddr)")
            }
            return (ip, port)
        }
    }

    private static func buildDictionary(configContents: String) -> [String: [String: String]] {
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
                    fatalError("Invalid INI file format")
                }
                dict[sectionName] = currentSection
            }
        }

        return dict
    }

}
