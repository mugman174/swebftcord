//
//  Embeds.swift
//  swebftcord
//
//  Created by mugman on 10/10/25.
//

import Foundation
import SwiftUI

enum StringOrInt: Codable, Hashable {
    case string(String), int(Int), none
    init (from decoder: any Decoder) throws {
        self = .none
        let c = try decoder.singleValueContainer()
        if c.decodeNil () {
            self = .none
        } else if let d = try? c.decode (Int.self) {
            self = .int(d)
        } else if let d = try? c.decode (String.self) {
            self = .string(d)
        } else {
            print("asdasd", c.codingPath)
        }
    }

    func encode(to encoder: any Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let string):
            try c.encode(string)
        case .int(let int):
            try c.encode(int)
        case .none:
            try c.encodeNil()
        }
    }
}

let hslaRegex = /hsla\((\d+), calc\(var\(--saturation-factor, 1\) \* (\d+\.?\d+)%\), (\d+\.?\d+)%, (\d+)\)/

struct Embed: Decodable, Hashable {
    var title: String? { _rawTitle ?? _title }
    let type: EmbedType?
    var description: String? { _rawDescription ?? _description }
    let url, timestamp: String?
    var color: StringOrInt?
    let footer: EmbedFooter?
    let image: EmbedMedia?
    let thumbnail: EmbedMedia?
    let video: EmbedVideo?
    let provider: EmbedProvider?
    let author: EmbedAuthor?
    let fields: [EmbedField]?


    let _rawTitle, _rawDescription, _title, _description: String?

    private enum CodingKeys: String, CodingKey {
        case type, url, timestamp, footer, image, color, thumbnail, video, provider, author, fields,
            _rawTitle = "rawTitle", _rawDescription = "rawDescription", _title = "title", _description = "description"
    }
}

enum EmbedType: String, Codable {
    case rich, image, video, gifv, article, link, pollResult
}

struct EmbedFooter: Codable, Hashable {
    let text: String
    let iconUrl, proxyIconUrl: String?
}

struct EmbedMedia: Codable, Hashable {
    let url: String
    var proxyURL: String?
    let height, width: Int?
}

struct EmbedVideo: Codable, Hashable {
    let url, proxyUrl: String?
    let height, width: Int?
}

struct EmbedProvider: Codable, Hashable {
    let name, url: String?
}

struct EmbedAuthor: Codable, Hashable {
    let name: String
    let url, iconUrl, iconProxyUrl: String?
}

struct EmbedField: Codable, Hashable {
    var name: String { _name ?? _rawName! }
    var value: String { _value ?? _rawValue! }
    let _name, _value, _rawName, _rawValue: String?
    let inline: Bool?

    private enum CodingKeys: String, CodingKey {
        case _rawName = "rawName", _rawValue = "rawValue", _name = "name", _value = "value", inline
    }
}
