//
//  ContentView.swift
//  swebftcord
//
//  Created by mugman on 05/2025.
//

import SwiftUI
import CoreData
import WebView
import WebKit

class MessageHandler: NSObject, WKScriptMessageHandler {
    @Binding var messages: [Message]
    @Binding var chosenChannel: String?

    override init() {
        self._messages = .constant(.init())
        self._chosenChannel = .constant(.init())
        super.init()
    }
    func realinit(messages: Binding<[Message]>, chosenChannel: Binding<String?>) {
        self._messages = messages
        self._chosenChannel = chosenChannel
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let data = message.body as? [String : Any] else {return}
        if ((data["channelId"] as! String) != chosenChannel) {return}
        messages
            .append(
                try! Message(data)
            )
    }
}

struct ContentView: View {
    @StateObject var webViewStore = WebViewStore()
    @State var showView = true
    @State var guilds: [Thing] = []
    @State var chosenGuild: String? = nil
    @State var channels: [Thing] = []
    @State var chosenChannel: String? = nil
    @State var messages: [Message] = []

    var body: some View {
        ZStack {
            VStack {
                if (showView) {
                    ProgressView(value: webViewStore.estimatedProgress)
                        .padding()
                }
                WebView(webView: webViewStore.webView)
                    .task {
                        await vencord()
                        webViewStore.webView.isInspectable = true
                        let rules = """
                    [{"trigger": {"url-filter": ".*", "resource-type": ["image", "font", "svg-document", "media", "other"]}, "action": { "type": "block"}}]
                    """
                        let rl = try! await WKContentRuleListStore.default().compileContentRuleList(
                            forIdentifier: "Rules",
                            encodedContentRuleList: rules
                        )
                        webViewStore.webView.configuration.userContentController
                            .add(rl!)
                        webViewStore.webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_7_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15"
                        let mh = MessageHandler()
                        mh
                            .realinit(messages: $messages, chosenChannel: $chosenChannel)
                        webViewStore.webView.configuration.userContentController
                            .add(mh, contentWorld: .page, name: "onMessage")
                        webViewStore.webView.load(URLRequest(url: URL(string: "https://discord.com/app")!))
                        while !((try? await runJS("return \(store("Guild"))?.isLoaded()") as? Bool) ?? false) {
                            try! await Task.sleep(for: .seconds(1))
                        }
                        showView = false

                    }
                    .frame(width: showView ? nil : 0, height: showView ? nil : 0)

            }
            if (!showView) {
                NavigationSplitView {
                    List($guilds, selection: $chosenGuild) { i in
                        Text(i.name.wrappedValue)
                    }
                    .refreshable {
                        try! await getGuilds()
                    }
                } content: {
                    if (chosenGuild != nil) {
                        List($channels, selection: $chosenChannel) { i in
                            Text(i.name.wrappedValue)
                        }
                        .task {
                            try! await getChannels(chosenGuild!)
                        }
                        .id(chosenGuild)
                    }
                } detail: {
                    if (chosenChannel != nil) {
                        MessageList(
                            messages: $messages,
                            chosenChannel: $chosenChannel,
                            getMessages: getMessages,
                            runJS: runJS
                        )
                        .scenePadding(.all)
                    }
                }
                .task {
                    try! await getGuilds()
                    _ = try! await runJS("""
                        Vencord.Webpack.Common.FluxDispatcher.subscribe("MESSAGE_CREATE", (m) => {
                            if (!m.optimistic) {
                                window.webkit.messageHandlers.onMessage.postMessage({channelId: m.channelId, author: {name: m.message.author.username, avatar: m.message.author.avatar, id: m.message.author.id}, content: m.message.content, id: m.message.id, attachments: m.attachments})
                            }
                        })
                        """)
                }
            }
        }

    }
    func addUserScript(_ script: WKUserScript) {
        webViewStore.webView.configuration.userContentController.addUserScript(script)
    }
    func vencord() async {
        webViewStore.webView.configuration.userContentController.removeAllUserScripts()
        addUserScript(await loadJS("https://github.com/Vencord/builds/raw/refs/heads/main/browser.js"))
        addUserScript(await loadCSS("https://github.com/Vencord/builds/raw/refs/heads/main/browser.css"))
    }

    func runJS(_ js: String, _ arguments: [String: Any] = [:]) async throws -> Any? {
        return try await webViewStore.webView
            .callAsyncJavaScript(js, arguments: arguments, contentWorld: .page)
    }

    func getGuilds() async throws {
        let lguilds = try await runJS("return Object.values(\(store("Guild")).getGuilds()).map(i=>{return {name:i.name, id:i.id}})")
        guilds = (lguilds as! [[String: String]])
            .map { try! .init($0)}
            .sorted(by: { $0.name < $1.name })
        guilds.insert(.init(name: "DMs", id: "@me"), at: 0)
        guilds.insert(.init(name: "Favorites", id: "@favorites"), at: 1)
    }

    func getChannels(_ guildId: String) async throws {
        let lchannels: Any?
        if (guildId == "@me") {
            lchannels = try await runJS("""
                channels = \(store("PrivateChannelSort")).getSortedChannels()[1].map(i=>\(store("Channel")).getChannel(i.channelId));
                return channels.map(i=>{return {name: (i.name || (i.recipients?.map(\(store("User")).getUser).map(i=>i.username).join(", ")) || i.id), id: i.id}});
                """)
        } else {
            lchannels = try await runJS(
                "return \(store("GuildChannel")).getChannels(guildId).SELECTABLE.map(i=>i.channel).map(i=>{return {name: i.name, id: i.id}})",
                ["guildId": guildId]
            )
        }
        channels = (lchannels as! [[String: String]]).map { try! .init($0)}
    }

    func goToChannel() async {
        _ = try! await runJS(
            "Vencord.Webpack.Common.NavigationRouter.transitionToGuild(guildId, channelId)",
            ["guildId": chosenGuild!, "channelId": chosenChannel!]
        )
    }

    func getMessages() async throws {
        print("MESSAGES")
        await goToChannel()
        try! await Task.sleep(for: .seconds(1)) // todo: wait for CHANNEL_SELECT flux event
        let lmessages = try! await runJS(
            "return \(store("Message")).getMessages(channel)._array.map(m=>{return {channelId: m.channel_id, author: {name: m.author.username, avatar: m.author.avatar, id: m.author.id}, content: m.content, id: m.id, attachments: m.attachments}})",
            ["channel": chosenChannel!]
        )
        let rmessages = (lmessages as! [[String: Any]])
        messages = rmessages
            .map {
                try! Message($0)
            }
    }
}
