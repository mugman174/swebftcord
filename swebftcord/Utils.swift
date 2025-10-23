//
//  JSHelpers.swift
//  swebftcord
//
//  Created by mugman on 05/2025.
//

import Foundation

func store(_ name: String) -> String {
    "Vencord.Webpack.findStore('\(name)Store')"
}

func avatar(_ author: Author) -> String {
    "https://cdn.discordapp.com/avatars/\(author.id)/\(author.avatar!).png?size=48"
}
