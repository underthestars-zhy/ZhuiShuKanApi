//
//  File.swift
//  
//
//  Created by 朱浩宇 on 2022/8/21.
//

import Foundation
import Zip

struct EpubGen {
    let contents: [Content]
    let searchResult: SearchResult
    let uuid = UUID().uuidString

    func gen(_ filePath: URL, progress: ((Double) -> ())? = nil) async throws {
        let folderURL = try createFolder(filePath)

        try createMETAINF(folderURL)
        try createMimetype(folderURL)
        let opsURL = try createOPS(folderURL)

        for (id, content) in contents.enumerated() {
            try genChapter(content, id: id + 1, ops: opsURL)
            progress?(Double(id + 1) / Double(contents.count) * 0.9)
        }

        try genNavigation(contents.map(\.title), ops: opsURL)

        try genOpf(ops: opsURL)

        try genToc(contents.map(\.title), ops: opsURL)

        try await genCover(ops: opsURL)

        let zipFilePath = filePath.appending(path: "\(searchResult.name).zip")
        let epubFilePath = filePath.appending(path: "\(searchResult.name).epub")

        try Zip.zipFiles(paths: [folderURL.appending(path: "META-INF"), folderURL.appending(path: "mimetype"), opsURL], zipFilePath: zipFilePath, password: nil) {
            progress?($0 * 0.1 + 0.9)
        }

        try FileManager.default.moveItem(at: zipFilePath, to: epubFilePath)

//        try FileManager.default.removeItem(at: folderURL)
    }

    // MARK: - Gen Chapter

    func genChapter(_ content: Content, id: Int, ops: URL) throws {
        var chapter = xhtml

        let xmlContent = content.content.map {
            "<p>\($0)</p>\n"
        }.reduce("", +)
        replace(&chapter, with: ["chapter-title" : content.title, "id" : "\(id)", "content" : xmlContent])

        let chapterURL = ops.appending(path: "chapter-\(id).xhtml")
        try chapter.data(using: .utf8)?.write(to: chapterURL)
    }

    // MARK: - Gen Navigation

    func genNavigation(_ titles: [String], ops: URL) throws {
        var navigation = navigationXhtml

        var content = ""

        for (id, title) in titles.enumerated() {
            content += "<li><a href=\"chapter-\(id + 1).xhtml\">\(title)</a></li>\n"
        }

        replace(&navigation, with: ["book-name" : searchResult.name, "content" : content])

        let navigationURL = ops.appending(path: "navigation.xhtml")
        try navigation.data(using: .utf8)?.write(to: navigationURL)
    }

    // MARK: - Gen Book Opf

    func genOpf(ops: URL) throws {
        var opf = bookOpf

        var content = ""

        for id in 1...contents.count {
            content += "<item id=\"chapter-\(id)\" href=\"chapter-\(id).xhtml\" media-type=\"application/xhtml+xml\" />\n"
        }

        var ncx = ""

        for id in 1...contents.count {
            ncx += "<itemref idref=\"chapter-\(id)\" />\n"
        }

        replace(&opf, with: ["book-name" : searchResult.name, "uuid": uuid, "html": content, "ncx": ncx])

        let opfURL = ops.appending(path: "book.opf")
        try opf.data(using: .utf8)?.write(to: opfURL)
    }

    // MARK: - Gen Toc

    func genToc(_ titles: [String], ops: URL) throws {
        var toc = toc

        var content = ""

        for (id, title) in titles.enumerated() {
            content += "<navPoint class=\"h1\" id=\"chapter-\(id + 1)\"><navLabel><text>\(title)</text></navLabel><content src=\"chapter-\(id + 1).xhtml#chapter-\(id + 1)\" /></navPoint>\n"
        }

        replace(&toc, with: ["book-name" : searchResult.name, "uuid": uuid, "navPoint": content])

        let tocURL = ops.appending(path: "toc.ncx")
        try toc.data(using: .utf8)?.write(to: tocURL)
    }

    // MARK: - Gen Cover

    func genCover(ops: URL) async throws {
        let (data, response) = try await URLSession.shared.data(from: searchResult.preview)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError()
        }

        try data.write(to: ops.appending(path: "cover.png"))

        var cover = cover

        replace(&cover, with: ["book-name" : searchResult.name])

        try cover.data(using: .utf8)?.write(to: ops.appending(path: "cover.xhtml"))
    }

    // MARK: - Gen defaul files

    func createFolder(_ filePath: URL) throws -> URL {
        let folder = filePath.appending(path: searchResult.name)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func createMETAINF(_ folderURL: URL) throws {
        let folder = folderURL.appending(path: "META-INF")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "container.xml")
        try container.data(using: .utf8)?.write(to: file)
    }

    func createMimetype(_ folderURL: URL) throws {
        let file = folderURL.appending(path: "mimetype")
        try minetype.data(using: .utf8)?.write(to: file)
    }

    func createOPS(_ folderURL: URL) throws -> URL {
        let folder = folderURL.appending(path: "OPS")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    // MARK: - Helper

    func replace(_ text: inout String, with dict: [String : String]) {
        for (value, key) in dict {
            text.replace("$(\(value))", with: key)
        }
    }
}
