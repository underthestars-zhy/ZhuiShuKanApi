import XCTest
@testable import ZhuiShuKanApi

final class ZhuiShuKanApiTests: XCTestCase {
    func testSearch() async throws {
        print(try await ZhuiShuKanApi.search(name: "我的姐姐是大明星"))
    }

    func testGetMenu() async throws {
        print(try await ZhuiShuKanApi.getMenu(URL(string: "https://m.ijjxsw.co/txt/37414.html")!))
    }

    func testGetContent() async throws {
        let menu = Menu(title: "第一章 姐弟", url: URL(string: "https://m.ijjxsw.co/txt/1909/2013578.html")!)
        print(try await ZhuiShuKanApi.parseContent(menu).content)
    }

    func testGenEpub() async throws {
        let search = SearchResult(name: "无声的证词（法医秦明系列2）", author: "法医秦明", preview: URL(string: "https://img.ijjxsw.co/16/16257/16257s.jpg")!, url: URL(string: "https://m.ijjxsw.co/txt/16257.html")!, type: .ijjxsw)

        let contents = [Content(title: "1", _content: ["1", "2"], fileURL: nil), Content(title: "2", _content: ["1", "2"], fileURL: nil)]

        try await EpubGen(contents: contents, searchResult: search).gen(URL(filePath: "/Users/zhuhaoyu/Downloads/test")) {
            print($0)
        }
    }

    func testFinal() async throws {
        let search = SearchResult(name: "无声的证词（法医秦明系列2）", author: "法医秦明", preview: URL(string: "https://img.ijjxsw.co/16/16257/16257s.jpg")!, url: URL(string: "https://m.ijjxsw.co/txt/16257.html")!, type: .ijjxsw)

        try await ZhuiShuKanApi.genEpub(at: URL(filePath: "/Users/zhuhaoyu/Downloads/test"), with: search) {
            print($0)
        }
    }

    func testZlibAvailableURL() async throws {
        print(try await Zlibrary.availableURL ?? "no url")
    }

    func testGetIntro() async throws {
        print(try await ZhuiShuKanApi.getIntro(from: SearchResult(name: "无声的证词（法医秦明系列2）", author: "法医秦明", preview: URL(string: "https://img.ijjxsw.co/16/16257/16257s.jpg")!, url: URL(string: "https://m.ijjxsw.co/txt/16257.html")!, type: .ijjxsw)))
    }

    func testSearchZlibrary() async throws {
        print(try await Zlibrary.search(name: "设计中的设计"))
    }

    func testGetZlibIntro() async throws {
        print(try await Zlibrary.getIntro(from: SearchResult(name: "设计中的设计）", author: "[日] 原研哉", preview: URL(string: "https://covers.zlibcdn2.com/covers200/books/70/a7/49/70a749c5ebdb3c9f1917fcf612c74469.jpg")!, url: URL(string: "https://b-ok.global/book/5294616/1e7bf9")!, type: .zlibrary)))
    }

    func testGetZlibDownloadLink() async throws {
        print(try await Zlibrary.getDonwloadLink(from: SearchResult(name: "设计中的设计）", author: "[日] 原研哉", preview: URL(string: "https://covers.zlibcdn2.com/covers200/books/70/a7/49/70a749c5ebdb3c9f1917fcf612c74469.jpg")!, url: URL(string: "https://b-ok.global/book/5294616/1e7bf9")!, type: .zlibrary)))
    }
}
