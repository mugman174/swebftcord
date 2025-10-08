//
//  MessageView.swift
//  swebftcord
//
//  Created by mugman on 10/8/25.
//
import SwiftUI
import CachedAsyncImage

struct MessageView: View {
    var message: Message
    let scrollReader: ScrollViewProxy
    @Binding var scrolledTo: String

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
                        CachedAsyncImage(url: avatar(message.author)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 16, height: 16)
                    }
                    Text(message.author.username)
                        .font(.caption)
                }
                HStack {
                    if let content = message.content {
                        Text(LocalizedStringKey(content))
                            .textSelection(.enabled)
                    }
                    VStack {
                        if let components = message.components {
                            ComponentView(components: components)
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
        .background(scrolledTo == message.id ? .yellow : .clear)

    }

}
