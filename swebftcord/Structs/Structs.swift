//
//  Structs.swift
//  swebftcord
//
//  Created by mugman on 05/2025.
//

import Foundation
import SwiftUI

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
    var embeds: [Embed]?
    var flags: MessageFlags

    init(_ dictionary: [String: Any]) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self = try decoder.decode(Message.self, from: JSONSerialization.data(withJSONObject: dictionary))
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
    let url: String
    let proxyUrl: String?
    let id, contentType, attachmentId, filename: String?
    let height, width: Int?
}

struct MessageFlags: OptionSet, Codable {
    let rawValue: UInt64

    /// Message has been published to subscribed channels (via Channel Following)
    static let crossposted = MessageFlags(rawValue: 1 << 0)
    /// Message originated from a message in another channel (via Channel Following)
    static let isCrosspost = MessageFlags(rawValue: 1 << 1)
    /// Embeds will not be included when serializing this message
    static let suppressEmbeds = MessageFlags(rawValue: 1 << 2)
    /// Source message for this crosspost has been deleted (via Channel Following)
    static let sourceMessageDeleted = MessageFlags(rawValue: 1 << 3)
    /// Message came from the urgent message system
    static let urgent = MessageFlags(rawValue: 1 << 4)
    /// Message has an associated thread, with the same ID as the message
    static let hasThread = MessageFlags(rawValue: 1 << 5)
    /// Message is only visible to the user who invoked the interaction
    static let ephemeral = MessageFlags(rawValue: 1 << 6)
    /// Message is an interaction response and the bot is "thinking"
    static let loading = MessageFlags(rawValue: 1 << 7)
    /// Some roles were not mentioned and added to the thread
    static let failedToMentionSomeRolesInThread = MessageFlags(rawValue: 1 << 8)
    /// Message is hidden from the guild's feed
    static let guildFeedHidden = MessageFlags(rawValue: 1 << 9)
    /// Message contains a link that impersonates Discord
    static let shouldShowLinkNotDiscordWarning = MessageFlags(rawValue: 1 << 10)
    /// Message will not trigger push and desktop notifications
    static let suppressNotifications = MessageFlags(rawValue: 1 << 12)
    /// Message's audio attachment is rendered as a voice message
    static let isVoiceMessage = MessageFlags(rawValue: 1 << 13)
    /// Message has a forwarded message snapshot attached
    static let hasSnapshot = MessageFlags(rawValue: 1 << 14)
    /// Message contains components from version 2 of the UI kit
    static let isComponentsV2 = MessageFlags(rawValue: 1 << 15)
    /// Message was triggered by the social layer integration
    static let sentBySocialLayerIntegration = MessageFlags(rawValue: 1 << 16)
}

struct GuildFolderData: Codable {
    let folderName: String?
    let folderId: Int?
    let guildIds: [String]

    private enum CodingKeys: String, CodingKey {
        case folderName, folderId, guildIds
    }

    init(_ dictionary: [String: Any]) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self = try decoder.decode(GuildFolderData.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}

struct Thingy: Identifiable, Codable {
    let id: String
    let name: String
    var children: [Thingy]?

    init(name: String, id: String, children: [Thingy]? = nil) {
        self.id = id
        self.name = name
        self.children = children
    }

    init(_ data: [String: Any], _ channels: [Thing]) {
        self.id = data["id"] as! String
        self.name = data["name"] as! String
        self.children = (data["channels"] as! [String]).compactMap { channel in
            channels.first(where: { $0.id == channel })
        }.map {
            .init(name: $0.name, id: $0.id)
        }
    }

    init(_ dictionary: [String: Any]) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self = try decoder.decode(Thingy.self, from: JSONSerialization.data(withJSONObject: dictionary))
    }
}
