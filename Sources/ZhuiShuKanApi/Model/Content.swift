//
//  File.swift
//  
//
//  Created by 朱浩宇 on 2022/8/20.
//

import Foundation

public struct Content {
    let title: String
    var content: [String] {
        if let _content {
            return _content
        } else if let fileURL {
            let data = try! Data(contentsOf: fileURL)

            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        } else {
            return []
        }
    }

    var string: String {
        content.reduce("", +)
    }

    let _content: [String]?
    let fileURL: URL?
}
