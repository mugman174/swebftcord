//
//  ComponentView.swift
//  swebftcord
//
//  Created by mugman on 10/8/25.
//
import SwiftUI

struct ComponentView: View {
    let components: [AnyComponent]
    @State var fcomponents: [AnyComponent] = []

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(fcomponents) { component in
                switch component {
                case .textDisplay(let textDisplay):
                    Text(textDisplay.content)
                case .container(let container):
                    ComponentView(components: container.components)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                case .section(let section):
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            ComponentView(components: section.components)
                        }
                        Spacer()
                        switch section.accessory {
                        case .thumbnail(let thumbnail):
                            AttachmentView(attachment: thumbnail.media)
                        case .button(let button):
                            CV2ButtonView(button: button)
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
                                CV2ButtonView(button: button)
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
        if let link = button.url, let url = URL(string: link) {
            Link(buttonLabel, destination: url)
                .clipShape(.buttonBorder)
        } else {
            Button(buttonLabel) {}
                .buttonStyle(.borderedProminent)
                .tint(buttonStyle)
        }
    }
}
