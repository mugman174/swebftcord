//
//  EmbedViews.swift
//  swebftcord
//
//  Created by mugman on 10/10/25.
//
import SwiftUI

func maybeURL(_ url: String?) -> URL? {
    if let url {
        return URL(string: url)
    }
    return nil
}

struct EmbedView: View {
    let embed: Embed
    var body: some View {
        VStack(alignment: .leading) {
            if let author = embed.author {
                HStack(alignment: .top) {
                    if let iconUrl = author.iconProxyUrl {
                        ImageView(url: iconUrl, maxHeight: 32)
                    }
                    if let url = maybeURL(author.url) {
                        Link(author.name, destination: url)
                            .font(.caption)
                            .textSelection(.enabled)

                    } else {
                        Text(author.name)
                            .font(.caption)
                            .textSelection(.enabled)

                    }
                }
            }
            if let title = embed.title {
                Text(title)
                    .font(.title)
                    .textSelection(.enabled)
            }
            if let description = embed.description {
                Text(description)
                    .textSelection(.enabled)
            }
            if let fields = embed.fields {
                HStack {
                    ForEach(fields, id: \.hashValue) { field in
                        VStack {
                            Text(field.name)
                                .bold()
                                .textSelection(.enabled)
                            Text(field.value)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            if let image = embed.image {
                if let url = image.proxyURL {
                    ImageView(url: url, maxHeight: 128)
                }
            }
            if let footer = embed.footer {
                if let iconUrl = footer.proxyIconUrl {
                    ImageView(url: iconUrl, maxHeight: 32)
                }
                Text(footer.text)
                    .font(.caption)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color(stringorint: embed.color) ?? .clear)
                .frame(width: 5)
        }
    }

}
