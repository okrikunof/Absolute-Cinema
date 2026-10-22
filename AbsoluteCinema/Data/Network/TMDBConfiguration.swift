import Foundation

struct TMDBConfiguration: Decodable, Sendable {
    let apiKey: String?
    let readAccessToken: String?

    private enum CodingKeys: String, CodingKey {
        case apiKey = "APIKey"
        case readAccessToken = "ReadAccessToken"
    }

    static func load() throws -> TMDBConfiguration {
        guard let url = Bundle.main.url(forResource: "TMDBConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let values = try? PropertyListDecoder().decode(Self.self, from: data) else {
            throw TMDBError.configuration
        }
        let configuration = TMDBConfiguration(
            apiKey: values.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
            readAccessToken: values.readAccessToken?.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        guard configuration.apiKey?.isEmpty == false
                || configuration.readAccessToken?.isEmpty == false else {
            throw TMDBError.configuration
        }
        return configuration
    }
}
