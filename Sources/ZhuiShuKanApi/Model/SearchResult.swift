//
//  File.swift
//  
//
//  Created by 朱浩宇 on 2022/8/20.
//

import Foundation

public struct SearchResult {
    public let name: String
    public let author: String
    public let preview: URL
    public let url: URL
    public let type: ResultType
}

public enum ResultType {
    case ijjxsw
    case zlibrary
}
