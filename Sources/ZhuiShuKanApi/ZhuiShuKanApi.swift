import Foundation
import SwiftSoup

public struct ZhuiShuKanApi {
    public static func search(name: String) async throws -> [SearchResult] {
        guard let URL = URL(string: "https://m.zhuishukan.com/search.html") else { return [] }
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"

        // Headers

        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0", forHTTPHeaderField: "User-Agent")
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.addValue("zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2", forHTTPHeaderField: "Accept-Language")
        request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("https://m.zhuishukan.com", forHTTPHeaderField: "Origin")
        request.addValue("https://m.zhuishukan.com/search.html", forHTTPHeaderField: "Referer")
        request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        request.addValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.addValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.addValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.addValue("?1", forHTTPHeaderField: "Sec-Fetch-User")
        request.addValue("waf_sc=5889647726; sex=boy; Hm_lvt_6a37d008dfb94eb8089427a50eaa8831=1660988392; Hm_lpvt_6a37d008dfb94eb8089427a50eaa8831=1660988461", forHTTPHeaderField: "Cookie")

        // Form URL-Encoded Body

        let bodyParameters = [
            "searchkey": name,
        ]
        let bodyString = bodyParameters.queryParameters
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        return try parseSearch(data)
    }

    // MARK: - Soup

    static func parseSearch(_ data: Data) throws -> [SearchResult] {
        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        let ul = try body.select("li")

        return try ul.array().compactMap { li in
            guard let name = try li.select("a").first()?.attr("title") else { return nil }
            guard let link = try li.select("a").first()?.attr("href"), let url = URL(string: link) else { return nil }
            guard let image = try li.select("a").first()?.select("img").first()?.attr("src"), let imageURL = URL(string: image)  else { return nil }
            let author = try li.select("a").array()[2].text()

            return SearchResult(name: name, author: author, preview: imageURL, url: url)
        }
    }

    static func createDoc(_ data: Data) throws -> Document {
        guard let html = String(data: data, encoding: .utf8) else { throw NSError() }
        return try SwiftSoup.parse(html)
    }
}
