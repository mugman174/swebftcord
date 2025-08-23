//
//  MessageList.swift
//  swebftcord
//
//  Created by mugman on 05/2025.
//

import SwiftUI
import Combine
import CachedAsyncImage

struct MessageView: View {
    var message: Message
    var onReply: ((Message) -> Void)?
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    if (message.author.avatar != nil) {
                        CachedAsyncImage(url: avatar(message.author)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 16, height: 16)
                    }
                    Text(message.author.name)
                        .font(.caption)
                }
                
                // Show replied message if this is a reply
                if let referencedMessage = message.referencedMessage {
                    HStack {
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 2)
                        VStack(alignment: .leading) {
                            Text("↪ \(referencedMessage.author.name)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(referencedMessage.content)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.leading, 4)
                }
                
                HStack {
                    Text(LocalizedStringKey(message.content))
                        .textSelection(.enabled)
                    if message.edited {
                        Image(systemName: "pencil")
                    }
                }
                if (
                    message.attachments != nil && !message.attachments!.isEmpty
                ) {
                    ScrollView(.horizontal) {
                        ForEach(message.attachments!) { attachment in
                            Link(destination: URL(string: attachment.url)!) {
                                if attachment.contentType?.starts(with: "image/") ?? false {
                                    CachedAsyncImage(url: URL(string: attachment.proxy_url)) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(maxHeight: 128)
                                } else {
                                    Text(
                                        attachment.filename
                                    )
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
            if let onReply = onReply {
                Button(action: { onReply(message) }) {
                    Image(systemName: "arrowshape.turn.up.left")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}


struct MessageList: View {
    @Binding var messages: [Message]
    @Binding var chosenChannel: String?
    var getMessages: () async throws -> Void
    var runJS: (String, [String : Any]) async throws -> Any?
    @State var messageContent: String = ""
    @State var replyingTo: Message? = nil

    var body: some View {
        VStack {
            ScrollViewReader { reader in
                ScrollView {
                    ForEach(messages) { message in
                        MessageView(message: message, onReply: { replyMessage in
                            replyingTo = replyMessage
                        })
                            .id(message.id)
                            .padding(
                                .init(top: 2, leading: 0, bottom: 2, trailing: 0)
                            )
                    }
                }
                .onReceive(Just(messages)) { _ in
                    if messages.last != nil {
                        reader.scrollTo(messages.last!.id)
                    }
                }

            }

            .task {
                try! await getMessages()
            }
            .defaultScrollAnchor(.bottom)
            
            // Reply preview
            if let replyingTo = replyingTo {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Replying to \(replyingTo.author.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(replyingTo.content)
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Cancel") {
                        self.replyingTo = nil
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            }
            
            HStack {
                TextField("Message", text: $messageContent)
                Button("Send") {
                    Task {
                        if let replyMessage = replyingTo {
                            // Send reply with message reference
                            _ = try! await runJS(
                                """
                                await Vencord.Util.sendMessage(Vencord.Util.getCurrentChannel().id, {
                                    content: content,
                                    message_reference: {
                                        message_id: replyMessageId
                                    }
                                })
                                """,
                                ["content": messageContent, "replyMessageId": replyMessage.id]
                            )
                        } else {
                            // Send normal message
                            _ = try! await runJS(
                                "await Vencord.Util.sendMessage(Vencord.Util.getCurrentChannel().id, {content})",
                                ["content": messageContent]
                            )
                        }
                        messageContent = ""
                        replyingTo = nil
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .id(chosenChannel)
    }
}
