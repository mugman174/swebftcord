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
                                    CachedAsyncImage(url: URL(string: attachment.url)) { image in
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
        }
    }

}

struct MessagesView: View {
    @Binding var messages: [Message]
    var runJS: (String, [String : Any]) async throws -> Any?

    var body: some View {
        ForEach(messages) { message in
            MessageView(message: message)
                .id(message.id)
                .padding(
                    .init(top: 2, leading: 0, bottom: 2, trailing: 0)
                )
        }
    }
}

struct MessageList: View {
    @Binding var messages: [Message]
    @Binding var chosenChannel: String?
    var getMessages: () async throws -> Void
    var runJS: (String, [String : Any]) async throws -> Any?
    @State var messageContent: String = ""

    var body: some View {
        VStack {
            ScrollViewReader { reader in
                ScrollView {
                    MessagesView(messages: $messages, runJS: runJS)
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
            HStack {
                TextField("Message", text: $messageContent)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    Task {
                        _ = try! await runJS(
                            "await Vencord.Util.sendMessage(Vencord.Util.getCurrentChannel().id, {content})",
                            ["content": messageContent]
                        )
                        messageContent = ""
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .id(chosenChannel)
    }
}
