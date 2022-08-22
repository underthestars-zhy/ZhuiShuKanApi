import XCTest
@testable import ZhuiShuKanApi

final class ZhuiShuKanApiTests: XCTestCase {
    func testSearch() async throws {
        print(try await ZhuiShuKanApi.search(name: "我的姐姐是大明星"))
    }

    func testGetMenu() async throws {
        print(try await ZhuiShuKanApi.getMenu(URL(string: "https://m.zhuishukan.com/book/776/id_776304.html")!))
    }

    func testGetContent() async throws {
        let menu = Menu(title: "第1章 遗产", url: URL(string: "https://m.zhuishukan.com/views/776/id_776304_215097.html")!)
        print(try await ZhuiShuKanApi.parseContent(menu).content)
    }

    func testGenEpub() async throws {
        let search = SearchResult(name: "原来我是妖二代", author: "卖报小郎君", preview: URL(string: "https://img.zhuishukan.com/files/article/image/224/224729/224729s.jpg")!, url: URL(string: "https://m.zhuishukan.com/book/776/id_776304.html")!)

        let contents = [Content(title: "1", _content: ["1", "2"], fileURL: nil), Content(title: "2", _content: ["1", "2"], fileURL: nil)]

        try await EpubGen(contents: contents, searchResult: search).gen(URL(filePath: "/Users/zhuhaoyu/Downloads/test")) {
            print($0)
        }
    }

    func testFinal() async throws {
        let search = SearchResult(name: "我的姐姐是大明星", author: "卖报小郎君", preview: URL(string: "https://img.zhuishukan.com/files/article/image/194/194276/194276s.jpg")!, url: URL(string: "https://m.zhuishukan.com/book/774/id_774490.html")!)

        try await ZhuiShuKanApi.genEpub(at: URL(filePath: "/Users/zhuhaoyu/Downloads/test"), with: search) {
            print($0)
        }
    }
}
