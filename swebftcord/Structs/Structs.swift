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
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self = try decoder.decode(Thing.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }

    init(name: String, id: String) {
        self.name = name
        self.id = id
    }
}

struct Message: Identifiable, Decodable {
    var author: Author
    var content: String?
    var id: String
    var channelId: String
    var attachments: [Attachment]?
    var edited: Bool = false
    var messageReference: MessageReference?
    var components: [AnyComponent]?

    init(_ dictionary: [String: Any]) throws {
        self = try JSONDecoder().decode(Message.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }

    init(_ dictionary: [String: Any], edited: Bool) throws {
        try self.init(dictionary)
        self.edited = edited
    }
}

struct MessageReference: Codable {
    var channelId, guildId, messageId: String?
}

struct Author: Identifiable, Codable {
    var username: String
    var avatar: String?
    var id: String
}

struct Attachment: Identifiable, Codable, Hashable {
    var url: String
    var id, proxyUrl, contentType, attachmentId, filename: String?
    let height, width: Int?
}
