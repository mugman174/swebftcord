//
//  MessageList.swift
//  swebftcord
//
//  Created by mugman on 05/2025.
//

import SwiftUI
import Combine
import CachedAsyncImage



struct AttachmentView: View {
    let attachment: Attachment
    var body: some View {
        Link(destination: URL(string: attachment.url)!) {
            if attachment.contentType?.starts(with: "image/") ?? false {
                AsyncImage(
                    url: URL(string: attachment.proxyUrl ?? attachment.url)
                ) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(maxHeight: 128)
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

    var body: some View {
        ForEach(messages) { message in
            MessageView(
                message: message,
                scrollReader: reader,
                scrolledTo: $scrolledTo
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
    var getMessages: () async throws -> Void
    var runJS: (String, [String : Any]) async throws -> Any?
    @State var messageContent: String = ""
    @State var scrolledTo: String = ""

    var body: some View {
        VStack {
            ScrollViewReader { reader in
                ScrollView {
                    MessagesView(messages: $messages, runJS: runJS, reader: reader, scrolledTo: $scrolledTo)
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
            #if os(macOS)
            .defaultScrollAnchor(.bottom)
            #endif
            HStack {
                TextField("Meow", text: $messageContent)
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
