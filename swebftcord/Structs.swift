//
//  Structs.swift
//  swebftcord
//
//  Created by mugman on 05/2025.
//

import Foundation

struct Thing: Identifiable, Codable {
    var name: String
    var id: String

    private enum CodingKeys: String, CodingKey {
        case name, id
    }

    init(_ dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(Thing.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }

    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

struct Message: Identifiable, Codable {
    var author: Author
    var content: String
    var id: String
    var channelId: String
    var attachments: [Attachment]?
    var edited: Bool = false

    private enum CodingKeys: String, CodingKey {
        case author, content, id, channelId, attachments, edited
    }

    init(_ dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }

    init(_ dictionary: [String: Any], edited: Bool) throws {
        self = try JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: dictionary))
        self.edited = edited
    }
}

struct Author: Identifiable, Codable {
    var username: String
    var avatar: String?
    var id: String

    private enum CodingKeys: String, CodingKey {
        case username, avatar, id
    }
}

struct Attachment: Identifiable, Codable {
    var proxy_url: String
    var url: String
    var id: String
    var contentType: String?
    var filename: String

    private enum CodingKeys: String, CodingKey {
        case proxy_url, url, id, contentType = "content_type", filename
    }
}
