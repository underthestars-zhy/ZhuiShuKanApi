import XCTest
@testable import ZhuiShuKanApi

final class ZhuiShuKanApiTests: XCTestCase {
    func testSearch() async throws {
        print(try await ZhuiShuKanApi.search(name: "诡秘之主"))
    }

    func testGetMenu() async throws {
        print(try await ZhuiShuKanApi.getMenu(URL(string: "https://m.ijjxsw.co/txt/37414.html")!))
    }

    func testGetContent() async throws {
        let menu = Menu(title: "第一章 姐弟", url: URL(string: "https://m.ijjxsw.co/txt/1909/2013578.html")!)
        print(try await ZhuiShuKanApi.parseContent(menu).content)
    }

    func testGenEpub() async throws {
        let search = SearchResult(name: "原来我是妖二代", author: "卖报小郎君", preview: URL(string: "https://img.zhuishukan.com/files/article/image/224/224729/224729s.jpg")!, url: URL(string: "https://m.zhuishukan.com/book/776/id_776304.html")!, introduction: "")

        let contents = [Content(title: "1", _content: ["1", "2"], fileURL: nil), Content(title: "2", _content: ["1", "2"], fileURL: nil)]

        try await EpubGen(contents: contents, searchResult: search).gen(URL(filePath: "/Users/zhuhaoyu/Downloads/test")) {
            print($0)
        }
    }

    func testFinal() async throws {
        let search = SearchResult(name: "原来我是妖二代", author: "卖报小郎君", preview: URL(string: "https://img.ijjxsw.co/1/1909/1909s.jpg")!, url: URL(string: "https://m.ijjxsw.co/txt/1909.html")!, introduction: "")

        try await ZhuiShuKanApi.genEpub(at: URL(filePath: "/Users/zhuhaoyu/Downloads/test"), with: search) {
            print($0)
        }
    }
}
