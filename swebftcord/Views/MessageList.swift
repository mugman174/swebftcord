//
//  MessageList.swift
//  swebftcord
//
//  Created by mugman on 05/2025.
//

import SwiftUI
import Combine
import NukeUI

struct ImageView: View {
    let url: String?
    let maxHeight: CGFloat
    var body: some View {
        LazyImage(
            url: maybeURL(url)
        ) { state in
            if let image = state.image {
                image.resizable()
                    .aspectRatio(contentMode: .fit)
            } else if state.error != nil {
                Image(systemName: "exclamationmark.triangle")
            } else {
                ProgressView()
            }
        }
        .frame(maxHeight: maxHeight)
    }
}


struct AttachmentView: View {
    let attachment: Attachment
    var body: some View {
        Link(destination: URL(string: attachment.url)!) {
            if attachment.contentType?.starts(with: "image/") ?? false {
                ImageView(
                    url: attachment.proxyUrl ?? attachment.url,
                    maxHeight: 128
                )
            } else {
                if let filename = attachment.filename {
                    Text(filename)
                } else if let filename = attachment.url
                    .split(separator: "/").last?
                    .split(separator: "?").first {
                    Text(String(filename))
                } else {
                    Text("??")
                }
            }
        }
    }
}

struct MessagesView: View {
    @Binding var messages: [Message]
    var runJS: (String, [String : Any]) async throws -> Any?
    let reader: ScrollViewProxy
    @Binding var scrolledTo: String
    let chosenGuild: String?

    var body: some View {
        ForEach(messages) { message in
            MessageView(
                message: message,
                scrollReader: reader,
                scrolledTo: $scrolledTo,
                chosenGuild: chosenGuild,
                runJS: runJS,
            )
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
    let chosenGuild: String?
    var getMessages: () async throws -> Void
    var runJS: (String, [String : Any]) async throws -> Any?
    @State var messageContent: String = ""
    @State var scrolledTo: String = ""

    var body: some View {
        VStack {
            ScrollViewReader { reader in
                ScrollView {
                    MessagesView(messages: $messages, runJS: runJS, reader: reader, scrolledTo: $scrolledTo, chosenGuild: chosenGuild)
                }
                .defaultScrollAnchor(.bottom)

            }
            .task {
                messages = []
                try! await getMessages()
            }
            #if os(macOS)
            .defaultScrollAnchor(.bottom)
            #endif
            HStack {
                TextField("Message", text: $messageContent)
                    .textFieldStyle(.roundedBorder)
                Button("Send") {
                    let mc = messageContent
                    messageContent = ""
                    Task {
                        _ = try! await runJS(
                            "await Vencord.Util.sendMessage(Vencord.Util.getCurrentChannel().id, {content})",
                            ["content": mc]
                        )
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .id(chosenChannel)
    }
}
