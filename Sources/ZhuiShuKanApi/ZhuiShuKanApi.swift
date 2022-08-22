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

    public static func getContent(_ search: SearchResult, progress: ((Double) -> ())? = nil) async throws -> [Content] {
        let menus = try await getMenu(search.url) {
            progress?($0 * 0.1)
        }

        var contents = [Content]()

        for (id, menu) in menus.enumerated() {
            contents.append(try await parseContent(menu))
            progress?(Double(id + 1) / Double(menus.count) * 0.9)
        }

        return contents
    }

    public static func genEpub(at filePath: URL, with searchResult: SearchResult, progress: ((Double) -> ())? = nil) async throws {
        let contents = try await getContent(searchResult) {
            progress?($0 * 0.5)
        }
        try await EpubGen(contents: contents, searchResult: searchResult).gen(filePath, progress: progress)
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
            guard let name = try li.select("a").first()?.attr("title") else { return nil }
            guard let link = try li.select("a").first()?.attr("href"), let url = URL(string: "https://m.zhuishukan.com" + link) else { return nil }
            guard let image = try li.select("a").first()?.select("img").first()?.attr("src"), let imageURL = URL(string: image)  else { return nil }
            let author = try li.select("a").array()[2].text()

            return SearchResult(name: name, author: author, preview: imageURL, url: url)
        }
    }

    static func parseDetail(_ data: Data) throws -> URL {
        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        let li = try body.getElementsByClass("now")

        guard let link = try li.select("a").first()?.attr("href") else { throw NSError() }

        guard let url = URL(string: "https://m.zhuishukan.com" + link) else { throw NSError() }

        return url
    }

    static func parseMenu(_ data: Data, progress: ((Double) -> ())? = nil) async throws -> [Menu] {
        let doc = try createDoc(data)

        guard let body = doc.body() else { throw NSError() }

        let pagelist = try body.getElementsByClass("pagelist")

        let urls = try pagelist.select("option").array().compactMap { option in
            URL(string: "https://m.zhuishukan.com" + (try option.attr("value")))
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

            let ul = try _body.getElementsByClass("read")

            let menus: [Menu] = try ul.select("li").compactMap { li in
                guard let name = try li.select("a").first()?.text() else { return nil }
                guard let link = try li.select("a").first()?.attr("href"), let url = URL(string: "https://m.zhuishukan.com" + link) else { return nil }

                return Menu(title: name, url: url)
            }

            res.append(contentsOf: menus)

            progress?(Double(id + 1) / Double(urls.count))
        }

        return res
    }

    static func parseContent(_ menu: Menu) async throws -> Content {
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

            let div = try body.getElementsByClass("azhuishukan_t62ff29a")

            var subDivs = try div.select("div").array().filter {
                try $0.className().isEmpty
            }

            subDivs.removeFirst()
            let last = try subDivs.removeLast().text()

            let endContent = content + (try subDivs.map {
                try $0.text()
            })

            let page = try body.getElementsByClass("pager z1")

            let a3 = try page.select("a").array()[2]

            if try a3.text() == "下一页", let _url = URL(string: "https://m.zhuishukan.com" + (try a3.attr("href"))) {
                return try await innerParse(_url, content: endContent)
            } else {
                return endContent + [last]
            }
        }

        return await Content(title: menu.title, content: try innerParse(menu.url))
    }

    static func createDoc(_ data: Data) throws -> Document {
        guard let html = String(data: data, encoding: .utf8) else { throw NSError() }
        return try SwiftSoup.parse(html)
    }
}
