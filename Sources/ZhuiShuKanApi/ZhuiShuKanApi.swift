import Foundation
import SwiftSoup

public struct ZhuiShuKanApi {
    public static func search(name: String) async throws -> [SearchResult] {
        guard let URL = URL(string: "https://m.ijjxsw.co/search/") else { return [] }
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"

        // Headers

        request.addValue("m.ijjxsw.co", forHTTPHeaderField: "Host")
        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:103.0) Gecko/20100101 Firefox/103.0", forHTTPHeaderField: "User-Agent")
        request.addValue("text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.addValue("zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2", forHTTPHeaderField: "Accept-Language")
        request.addValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.addValue("https://m.ijjxsw.co", forHTTPHeaderField: "Origin")
        request.addValue("1", forHTTPHeaderField: "DNT")
        request.addValue("https://m.ijjxsw.co/", forHTTPHeaderField: "Referer")
        request.addValue("1", forHTTPHeaderField: "Upgrade-Insecure-Requests")
        request.addValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
        request.addValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.addValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.addValue("?1", forHTTPHeaderField: "Sec-Fetch-User")

        // Form URL-Encoded Body

        let bodyParameters = [
            "show": "writer,title",
            "searchkey": name,
            "Submit22": "搜索",
        ]
        let bodyString = bodyParameters.queryParameters
        request.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        return try parseSearch(data)
    }

    public static func getContent(_ search: SearchResult, temp fileURL: URL? = nil, progress: ((Double) -> ())? = nil) async throws -> [Content] {
        let menus = try await getMenu(search.url) {
            progress?($0 * 0.1)
        }

        var contents = [Content]()

        for (id, menu) in menus.enumerated() {
            contents.append(try await parseContent(menu, fileURL: fileURL))
            progress?(Double(id + 1) / Double(menus.count) * 0.9 + 0.1)
        }

        return contents
    }

    public static func genEpub(at filePath: URL, with searchResult: SearchResult, temp fileURL: URL? = nil, progress: ((Double) -> ())? = nil) async throws {
        let contents = try await getContent(searchResult, temp: fileURL) {
            progress?($0 * 0.5)
        }

        try await EpubGen(contents: contents, searchResult: searchResult).gen(filePath) {
            progress?(0.5 + $0 * 0.5)
        }

        progress?(1)
    }

    public static func getIntro(from search: SearchResult) async throws -> String {
        var request = URLRequest(url: search.url)
        request.httpMethod = "GET"

        request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        var text = try body.getElementById("content")?.select("p").array().reduce("", { partialResult, p in
            partialResult + (try p.text()) + "\n"
        })

        text?.removeLast()

        return text ?? ""
    }

    // MARK: - Auxiliary

    static func getMenu(_ url: URL, progress: ((Double) -> ())? = nil) async throws -> [Menu] {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        let menuURL = try parseDetail(data)

        let (menuData, menuResponse) = try await URLSession.shared.data(from: menuURL)

        guard (menuResponse as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        return try await parseMenu(menuData, progress: progress)
    }

    // MARK: - Soup

    static func parseSearch(_ data: Data) throws -> [SearchResult] {
        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        let ul = try body.select("li")

        return try ul.array().compactMap { li in
            guard let name = try li.select("strong").first()?.text() else { return nil }
            guard let link = try li.select("a").first()?.attr("href"), let url = URL(string: "https://m.ijjxsw.co" + link) else { return nil }
            guard let image = try li.select("img").first()?.attr("src"), let imageURL = URL(string: image) else { return nil }
            guard var author = try li.select("span").first()?.text() else { return nil }
            author.removeFirst()
            author.removeFirst()
            author.removeFirst()

            return SearchResult(name: name, author: author, preview: imageURL, url: url, type: .ijjxsw)
        }
    }

    static func parseDetail(_ data: Data) throws -> URL {
        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        let li = try body.getElementsByClass("read")

        guard let link = try li.select("a").first()?.attr("href") else { throw NSError() }

        guard let url = URL(string: "https://m.ijjxsw.co" + link) else { throw NSError() }

        return url
    }

    static func parseMenu(_ data: Data, progress: ((Double) -> ())? = nil) async throws -> [Menu] {
        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        let pagelist = try body.getElementsByClass("text")

        let urls = try pagelist.select("option").array().compactMap { option in
            URL(string: "https://m.ijjxsw.co" + (try option.attr("value")))
        }

        var res = [Menu]()

        for (id, url) in urls.enumerated() {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0", forHTTPHeaderField: "User-Agent")

            let (_data, response) = try await URLSession.shared.data(for: request)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw NSError()
            }

            let _doc = try createDoc(_data)

            guard let _body = _doc.body() else { throw NSError() }

            guard let div = try _body.getElementsByClass("sso_a").first() else { throw NSError() }

            let menus: [Menu] = try div.select("li").compactMap { li in
                guard let name = try li.select("a").first()?.text() else { return nil }
                guard let link = try li.select("a").first()?.attr("href"), let url = URL(string: "https://m.ijjxsw.co" + link) else { return nil }

                return Menu(title: name, url: url)
            }

            res.append(contentsOf: menus)

            progress?(Double(id + 1) / Double(urls.count))
        }

        return res
    }

    static func parseContent(_ menu: Menu, fileURL: URL? = nil) async throws -> Content {
        func innerParse(_ url: URL, content: [String] = []) async throws -> [String] {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            request.addValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:102.0) Gecko/20100101 Firefox/102.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw NSError()
            }

            let doc = try createDoc(data)

            guard let body = doc.body() else { throw NSError() }

            guard let span = try body.getElementById("Content") else { throw NSError() }

            let endContent = content + (try span.select("p").map {
                let regex1 = #/<.+>/#
                let regex2 = #/<\\.+>/#
                return try $0.text().replacing(regex1, with: "").replacing(regex2, with: "")
            }.filter {
                $0 != "最快更新" && $0 != "" && !($0.contains("&ap")) && !($0.contains("/txt")) && !($0.contains("手机版阅读网址"))
            })

            guard let next = try body.getElementById("next_url") else { throw NSError() }

            if try next.text() == "下一页", let _url = URL(string: "https://m.ijjxsw.co" + (try next.attr("href"))) {
                return try await innerParse(_url, content: endContent)
            } else {
                return endContent
            }
        }

        if let fileURL {
            let saveFileURl = fileURL.appending(path: "\(UUID()).json")
            let contents = try await innerParse(menu.url)
            try JSONEncoder().encode(contents).write(to: saveFileURl)
            return Content(title: menu.title, _content: nil, fileURL: saveFileURl)
        } else {
            return await Content(title: menu.title, _content: try innerParse(menu.url), fileURL: nil)
        }
    }

    static func createDoc(_ data: Data) throws -> Document {
        guard let html = String(data: data, encoding: .utf8) else { throw NSError() }
        return try SwiftSoup.parse(html)
    }
}
