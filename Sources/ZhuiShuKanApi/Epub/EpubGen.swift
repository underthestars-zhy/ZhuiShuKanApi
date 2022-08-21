//
//  File.swift
//  
//
//  Created by 朱浩宇 on 2022/8/21.
//

import Foundation

struct EpubGen {
    let title: String
    let contents: [Content]

    func gen(_ filePath: URL) throws {
        let folderURL = try createFolder(filePath)

        try createMETAINF(folderURL)
        createMimetype(folderURL)
        let opsURL = try createOPS(folderURL)

        
    }

    func createFolder(_ filePath: URL) throws -> URL {
        let folder = filePath.appending(path: title)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    func createMETAINF(_ folderURL: URL) throws {
        let folder = folderURL.appending(path: "META-INF")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let file = folder.appending(path: "container.xml")
        FileManager.default.createFile(atPath: file.path(), contents: container.data(using: .utf8))
    }

    func createMimetype(_ folderURL: URL) {
        let file = folderURL.appending(path: "mimetype")
        FileManager.default.createFile(atPath: file.path(), contents: minetype.data(using: .utf8))
    }

    func createOPS(_ folderURL: URL) throws -> URL {
        let folder = folderURL.appending(path: "OPS")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
