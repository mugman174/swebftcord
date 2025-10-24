//
//  MessageView.swift
//  swebftcord
//
//  Created by mugman on 10/8/25.
//
import SwiftUI
import NukeUI

struct MessageView: View {
    let message: Message
    @State var content: AttributedString?
    let scrollReader: ScrollViewProxy
    @Binding var scrolledTo: String
    let chosenGuild: String?
    let runJS: (String, [String : Any]) async throws -> Any?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                if let id = message.messageReference?.messageId {
                    HStack {
                        Button {
                            withAnimation {
                                scrolledTo = id
                                scrollReader.scrollTo(id)
                                Task(priority: .background) {
                                    try? await Task.sleep(for: .seconds(2))
                                    if scrolledTo == id {
                                        scrolledTo = ""
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.turn.up.right")
                            Text("Jump to Reply")
                                .font(.caption.italic())
                        }
                    }
                }
                HStack {
                    if (message.author.avatar != nil) {
                        ImageView(url: avatar(message.author), maxHeight: 16)
                        .clipShape(.circle)
                    }
                    Text(message.author.username)
                        .font(.caption)
                }
                HStack {
                    VStack(alignment: .leading) {
                        if let content {
                            Text(content)
                                .textSelection(.enabled)
                        }
                        if let embeds = message.embeds {
                            VStack {
                                ForEach(embeds, id: \.hashValue) { embed in
                                    EmbedView(embed: embed)
                                }
                            }
                        }
                        if let components = message.components {
                            ComponentView(
                                components: components,
                                buttonContext: ButtonContext(
                                    messageId: message.id,
                                    messageFlags: message.flags,
                                    applicationId: message.author.id,
                                    channelId: message.channelId,
                                    guildId: chosenGuild,
                                    runJS: runJS,
                                )
                            )
                        }
                    }
                    if message.edited {
                        Image(systemName: "pencil")
                    }
                }
                if (
                    message.attachments != nil && !message.attachments!.isEmpty
                ) {
                    ScrollView(.horizontal) {
                        ForEach(message.attachments!) { attachment in
                            AttachmentView(attachment: attachment)
                        }
                    }
                }
            }
            Spacer()
        }
        .background(
            scrolledTo == message.id ? .yellow : message.flags
                .contains(.ephemeral) ? .blue.opacity(0.25) : .clear
        )
        .task {
            await parseMentions()
        }

    }

    func parseMentions() async {
        guard let mcontent = message.content else {return}
        let mentionRegex = /<@!?(\d+)>/
        let getNickname = "Vencord.Webpack.findByProps('getNickname').getNickname"
        let getName = "Vencord.Webpack.findByProps('getName', 'getUserIsStaff').getName"
        var cache: [String: String] = [:]

        let matches = mcontent.matches(of: mentionRegex)

        for userId in matches.map({ String($0.1) }) {
            if cache.keys
                .contains(where: { $0 == userId }) {
                continue
            }
            let userObject = try! await runJS("return JSON.parse(JSON.stringify(\(store("User")).getUser(userId) || null))", ["userId": userId]) as? [String: Any]

            guard let userObject else {continue}
            let name = try! await runJS(
                "return \(getNickname)(guildId, channelId, userObj) || \(getName)(userObj)",
                [
                    "guildId": chosenGuild as Any,
                    "channelId": message.channelId,
                    "userObj": userObject
                ]
            ) as! String
            cache[userId] = name
        }
        guard var acontent = try? AttributedString(
            markdown: mcontent,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible,
            )
        ) else {return}
        // TODO: fix offsets caused by codeblocks and other things that remove characters
        for match in matches.reversed() {
            let s: String
            if let item = cache.first(where: { key, value in
                key == String(match.output.1)
            }) {
                s = "@\(item.value)"
            } else {
                s = "@unknown-user"
            }
            var at = AttributedString(s)
            at.backgroundColor = .blue
            guard let range: Range<AttributedString.Index> = .init(
                match.range,
                in: acontent
            ) else {continue}
            acontent.replaceSubrange(range, with: at)
        }
        content = acontent
    }

}
