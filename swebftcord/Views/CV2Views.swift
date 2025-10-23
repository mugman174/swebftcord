//
//  ComponentView.swift
//  swebftcord
//
//  Created by mugman on 10/8/25.
//
import SwiftUI

struct ComponentView: View {
    let components: [AnyComponent]
    let buttonContext: ButtonContext
    @State var fcomponents: [AnyComponent] = []

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(fcomponents) { component in
                switch component {
                case .textDisplay(let textDisplay):
                    Text(textDisplay.content)
                        .textSelection(.enabled)
                case .container(let container):
                    ComponentView(components: container.components, buttonContext: buttonContext)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .overlay(alignment: .leading) {
                            Rectangle()
                                .fill(
                                    Color(
                                        stringorint: container.accentColor
                                    ) ?? .clear
                                )
                                .frame(width: 5)
                        }
                case .section(let section):
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            ComponentView(components: section.components, buttonContext: buttonContext)
                        }
                        Spacer()
                        switch section.accessory {
                        case .thumbnail(let thumbnail):
                            AttachmentView(attachment: thumbnail.media)
                        case .button(let button):
                            CV2ButtonView(button: button, buttonContext: buttonContext)
                        default:
                            Text("ACCESSORY")
                                .background(.red)
                        }
                    }
                case .mediaGallery(let mediaGallery):
                    ScrollView(.horizontal) {
                        ForEach(mediaGallery.items) { media in
                            AttachmentView(attachment: media.media)
                        }
                    }
                case .actionRow(let actionRow):
                    HStack(alignment: .top) {
                        ForEach(actionRow.components) { cmp in
                            switch cmp {
                            case .button(let button):
                                CV2ButtonView(button: button, buttonContext: buttonContext)
                            default:
                                Text("COMPONENT")
                                    .background(.red)
                            }
                        }
                    }
                default:
                    Text("COMPONENT")
                        .background(.red)
                }
            }
            .id(fcomponents)
        }
        .onAppear {
            fcomponents = components.filter {
                switch $0 {
                case .textDisplay, .container, .section, .mediaGallery, .actionRow:
                    true
                default:
                    false
                }
            }
        }
    }
}

struct CV2ButtonView: View {
    let button: CV2Button
    let buttonContext: ButtonContext
    var buttonLabel: String { button.label ?? "Premium" }
    var buttonStyle: Color? {
        switch button.style {
        case .primary:
            nil
        case .secondary:
            .gray
        case .link:
            .blue
        case .premium:
            .purple
        case .success:
            .green
        case .danger:
            .red
        }
    }

    var body: some View {
        if let url = maybeURL(button.url) {
            Link(buttonLabel, destination: url)
                .clipShape(.buttonBorder)
        } else {
            Button(buttonLabel) { Task(operation: onClick) }
                .buttonStyle(.borderedProminent)
                .tint(buttonStyle)
        }
    }

    private struct ButtonClickRequest: Codable {
        let componentType: ComponentType
        let messageId: String
        let messageFlags: MessageFlags
        let customId, componentId, applicationId, channelId: String
        let guildId: String?

        init(
            customId: String,
            componentId: String,
            buttonContext: ButtonContext,
        ) {
            self.componentType = .button
            self.messageId = buttonContext.messageId
            self.messageFlags = buttonContext.messageFlags
            self.customId = customId
            self.componentId = componentId
            self.applicationId = buttonContext.applicationId
            self.channelId = buttonContext.channelId
            if buttonContext.guildId?.allSatisfy({ $0.isNumber }) == true {
                self.guildId =  buttonContext.guildId
            } else {
                self.guildId = nil
            }
        }

        func encode() -> [String: Any] {
            return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
        }
    }

    func onClick() async {
        let req = ButtonClickRequest(
            customId: button.customId!,
            componentId: button.id!,
            buttonContext: buttonContext
        )
        let data = req.encode()
        _ = try? await buttonContext.runJS("await Vencord.Webpack.findByCode(\".canQueueInteraction(\")({componentType, messageId, messageFlags, customId, componentId, applicationId, channelId, guildId, localState: null})", data)
    }
}

struct ButtonContext {
    let messageId: String
    let messageFlags: MessageFlags
    let applicationId: String
    let channelId: String
    let guildId: String?
    let runJS: (String, [String : Any]) async throws -> Any?
}
