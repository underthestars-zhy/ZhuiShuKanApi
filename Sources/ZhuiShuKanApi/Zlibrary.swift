import Foundation

public struct Zlibrary {
    public static var availableURL: URL? {
        get async throws {
            for urlString in zlibraryURLs {
                guard let url = URL(string: "https://" + urlString) else { continue }

                let (_, response) = try await URLSession.shared.data(from: url)

                if (response as? HTTPURLResponse)?.statusCode == 200 {
                    return url
                }
            }

            return nil
        }
    }

    public static func search(name: String) async throws -> [SearchResult] {
        guard let availableURL = try await availableURL else { return [] }

        let searchURL = availableURL.appending(path: "s").appending(path: name.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? name)

        let (data, response) = try await URLSession.shared.data(from: searchURL)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        return []
    }
}
