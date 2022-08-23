import Foundation
import SwiftSoup

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

        let searchURL = availableURL.appending(path: "s").appending(path: name + "?")

        var request = URLRequest(url: searchURL)
        request.httpMethod = "GET"

        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        guard let items = try body.getElementById("searchResultBox")?.select("table").array().filter({ $0.hasClass("resItemTable") }) else { throw NSError() }
        
        return try items.compactMap {
            guard try $0.getElementsByClass("bookDetailsBox").first()?.getElementsByClass("property_value").dropLast(1).last?.text().contains("EPUB") ?? false else { return nil }
            guard let urlString = try $0.select("a").first()?.attr("href") else { return nil }
            let url = availableURL.appending(path: urlString)
            guard var previewString = try $0.select("img").first()?.attr("data-src") else { return nil }
            previewString.replace("covers100", with: "covers200")
            guard let preview = URL(string: previewString) else { return nil }
            guard let name = try $0.select("h3").first()?.select("a").text() else { return nil }
            guard let author = try $0.getElementsByClass("authors").first()?.select("a").text() else { return nil }

            return SearchResult(name: name, author: author, preview: preview, url: url, type: .zlibrary)
        }
    }

    // MARK: - Soup

    static func createDoc(_ data: Data) throws -> Document {
        guard let html = String(data: data, encoding: .utf8) else { throw NSError() }
        return try SwiftSoup.parse(html)
    }
}
