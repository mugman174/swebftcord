import Foundation

typealias Snowflake = String

@propertyWrapper
struct StringId: Codable, Hashable {
    var wrappedValue: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            wrappedValue = String(intValue)
        } else {
            wrappedValue = try container.decode(String.self)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}


struct Emoji: Codable, Hashable {
    @StringId var id: String?
    let name: String?
}

enum ComponentType: Int, Codable {
    case actionRow = 1, button, stringSelect, textInput, userSelect, roleSelect, mentionableSelect, channelSelect, section, textDisplay, thumbnail, mediaGallery, file, separator, container = 17, label
}

protocol Component: Decodable, Hashable {
    var id: String? { get }
    var type: ComponentType { get }
}

protocol InteractiveComponent: Component {
    var customId: String? { get }
}

struct ActionRow: Component {
    @StringId var id: String?
    let type: ComponentType = .actionRow
    let components: [AnyComponent]
    private enum CodingKeys: String, CodingKey {
        case id, components
    }
}

struct CV2Button: InteractiveComponent {
    let type: ComponentType = .button
    @StringId var id: String?
    let style: Self.Style
    let label: String?
    let emoji: Emoji?
    let customId: String?
    let skuId: Snowflake?
    let url: String?
    let disabled: Bool?

    enum Style: Int, Codable {
        case primary = 1, secondary, success, danger, link, premium
    }

    private enum CodingKeys: String, CodingKey {
        case id, style, label, emoji, customId, skuId, url, disabled
    }
}

struct StringSelect: InteractiveComponent {
    let type: ComponentType = .stringSelect
    @StringId var id: String?
    let customId: String?
    let options: [Self.SelectOption]
    let placeholder: String?
    let min_values, max_values: Int?
    let required, disabled: Bool?

    struct SelectOption: Codable, Hashable {
        let label: String
        let value: String
        let description: String?
        let emoji: Emoji?
        let `default`: Bool?
    }

    private enum CodingKeys: String, CodingKey {
        case id, customId, options, placeholder, min_values, max_values, required, disabled
    }
}

struct TextInput: InteractiveComponent {
    let type: ComponentType = .textInput
    @StringId var id: String?
    let customId: String?
    let style: Self.TextInputStyle
    let minLength, maxLength: Int?
    let required: Bool?
    let value: String?
    let placeholder: String?

    enum TextInputStyle: Int, Codable {
        case short = 1, paragraph
    }

    private enum CodingKeys: String, CodingKey {
        case id, customId, style, minLength, maxLength, required, value, placeholder
    }
}

struct DefaultValues: Codable, Hashable {
    let id: Snowflake
    let type: Self.DefaultValueTypes

    enum DefaultValueTypes: String, Codable {
        case user, role, channel
    }
}

struct UserSelect: InteractiveComponent {
    let type: ComponentType = .userSelect
    @StringId var id: String?
    let customId: String?
    let placeholder: String?
    let defaultValues: [DefaultValues]?
    let minValues, maxValues: Int?
    let required, disabled: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, customId, placeholder, defaultValues, minValues, maxValues, required, disabled
    }
}

struct RoleSelect: InteractiveComponent {
    let type: ComponentType = .roleSelect
    @StringId var id: String?
    let customId: String?
    let placeholder: String?
    let defaultValues: [DefaultValues]?
    let minValues, maxValues: Int?
    let required, disabled: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, customId, placeholder, defaultValues, minValues, maxValues, required, disabled
    }
}

struct MentionableSelect: InteractiveComponent {
    let type: ComponentType = .mentionableSelect
    @StringId var id: String?
    let customId: String?
    let placeholder: String?
    let defaultValues: [DefaultValues]?
    let minValues, maxValues: Int?
    let required, disabled: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, customId, placeholder, defaultValues, minValues, maxValues, required, disabled
    }
}

struct ChannelSelect: InteractiveComponent {
    let type: ComponentType = .channelSelect
    @StringId var id: String?
    let customId: String?
    let placeholder: String?
    let defaultValues: [DefaultValues]?
    let minValues, maxValues: Int?
    let required, disabled: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, customId, placeholder, defaultValues, minValues, maxValues, required, disabled
    }
}

struct CV2Section: Component {
    let type: ComponentType = .section
    @StringId var id: String?
    let components: [AnyComponent]
    let accessory: AnyComponent

    private enum CodingKeys: String, CodingKey {
        case id, components, accessory
    }
}

struct TextDisplay: Component {
    let type: ComponentType = .textDisplay
    @StringId var id: String?
    let content: String

    private enum CodingKeys: String, CodingKey {
        case id, content
    }
}

struct Thumbnail: Component {
    let type: ComponentType = .thumbnail
    @StringId var id: String?
    let media: Attachment
    let description: String?
    let spoiler: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, media, description, spoiler
    }
}

struct MediaGallery: Component {
    let type: ComponentType = .mediaGallery
    @StringId var id: String?
    let items: [MediaGalleryItem]

    struct MediaGalleryItem: Codable, Hashable, Identifiable {
        let media: Attachment
        let description: String?
        let spoiler: Bool?
        var id: String {self.media.attachmentId ?? self.media.id ?? UUID().uuidString}

        private enum CodingKeys: String, CodingKey {
            case media, description, spoiler
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id, items
    }
}

struct File: Component {
    let type: ComponentType = .file
    @StringId var id: String?
    let file: Attachment
    let spoiler: Bool?
    let name: String
    let size: Int

    private enum CodingKeys: String, CodingKey {
        case id, file, spoiler, name, size
    }
}

struct Separator: Component {
    let type: ComponentType = .separator
    @StringId var id: String?
    let divider: Bool?
    let spacing: Int?

    private enum CodingKeys: String, CodingKey {
        case id, divider, spacing
    }
}

struct Container: Component {
    let type: ComponentType = .container
    @StringId var id: String?
    let components: [AnyComponent]
    let accentColor: Int?
    let spoiler: Bool?

    private enum CodingKeys: String, CodingKey {
        case id, components, accentColor, spoiler
    }
}

struct CV2Label: Component {
    let type: ComponentType = .label
    @StringId var id: String?
    let label: String
    let description: String?
    let component: AnyComponent

    private enum CodingKeys: String, CodingKey {
        case id, label, description, component
    }
}

indirect enum AnyComponent: Decodable, Identifiable, Hashable {
    case actionRow(ActionRow)
    case button(CV2Button)
    case stringSelect(StringSelect)
    case textInput(TextInput)
    case userSelect(UserSelect)
    case roleSelect(RoleSelect)
    case mentionableSelect(MentionableSelect)
    case channelSelect(ChannelSelect)
    case section(CV2Section)
    case textDisplay(TextDisplay)
    case thumbnail(Thumbnail)
    case mediaGallery(MediaGallery)
    case file(File)
    case separator(Separator)
    case container(Container)
    case label(CV2Label)

    private enum CodingKeys: String, CodingKey {
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ComponentType.self, forKey: .type)
        switch type {
        case .button:
            self = .button(try CV2Button(from: decoder))
        case .actionRow:
            self = .actionRow(try ActionRow(from: decoder))
        case .channelSelect:
            self = .channelSelect(try ChannelSelect(from: decoder))
        case .stringSelect:
            self = .stringSelect(try StringSelect(from: decoder))
        case .textInput:
            self = .textInput(try TextInput(from: decoder))
        case .userSelect:
            self = .userSelect(try UserSelect(from: decoder))
        case .roleSelect:
            self = .roleSelect(try RoleSelect(from: decoder))
        case .mentionableSelect:
            self = .mentionableSelect(try MentionableSelect(from: decoder))
        case .section:
            self = .section(try CV2Section(from: decoder))
        case .textDisplay:
            self = .textDisplay(try TextDisplay(from: decoder))
        case .thumbnail:
            self = .thumbnail(try Thumbnail(from: decoder))
        case .mediaGallery:
            self = .mediaGallery(try MediaGallery(from: decoder))
        case .file:
            self = .file(try File(from: decoder))
        case .separator:
            self = .separator(try Separator(from: decoder))
        case .container:
            self = .container(try Container(from: decoder))
        case .label:
            self = .label(try CV2Label(from: decoder))
        }
    }

    var id: UUID {UUID()}
}
