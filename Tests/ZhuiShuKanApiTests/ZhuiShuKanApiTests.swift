import XCTest
@testable import ZhuiShuKanApi

final class ZhuiShuKanApiTests: XCTestCase {
    func testSearch() async throws {
        print(try await ZhuiShuKanApi.search(name: "原来我是妖二代"))
    }

    func testGetMenu() async throws {
        print(try await ZhuiShuKanApi.getMenu(URL(string: "https://m.zhuishukan.com/book/776/id_776304.html")!))
    }
}
