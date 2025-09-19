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
        if ((data["channelId"] as? String) != chosenChannel) {return}
        let msg_id = data["id"] as! String
        switch data["type"] as! String {
        case "MESSAGE_CREATE":
            messages
                .append(
                    try! Message(data)
                )
        case "MESSAGE_UPDATE":
            if let idx = messages.firstIndex(where: { $0.id == msg_id }) {
                messages[idx] = try! Message(data, edited: true)
            }
        case "MESSAGE_DELETE":
            messages.removeAll { $0.id == msg_id }
        default:
            return
        }
    }
}

struct ContentScene: Scene {
    @StateObject var webViewStore = WebViewStore()
    @State var showView = true
    @State var guilds: [Thing] = []
    @State var chosenGuild: String? = nil
    @State var channels: [Thing] = []
    @State var chosenChannel: String? = nil
    @State var messages: [Message] = []
    @State var pingCountText: String = ""
    let reg = try! Regex("\\(([0-9]+)\\)")

    var body: some Scene {
        #if false // swebftcord in the menu bar
        MenuBarExtra() {
            AllTheThings(
                webViewStore: webViewStore,
                showView: $showView,
                guilds: $guilds,
                chosenGuild: $chosenGuild,
                channels: $channels,
                chosenChannel: $chosenChannel,
                messages: $messages,
            )
        } label: {
            Image(.scor)
            Text(pingCountText)
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 640, height: 480)
        .onChange(of: webViewStore.webView.title) { _ in
            if let match = (webViewStore.webView.title ?? "").firstMatch(of: reg) {
                pingCountText = "\(match.first!.value!)"
            } else {
                pingCountText = ""
            }
        }
        #else
        WindowGroup {
            AllTheThings(
                webViewStore: webViewStore,
                showView: $showView,
                guilds: $guilds,
                chosenGuild: $chosenGuild,
                channels: $channels,
                chosenChannel: $chosenChannel,
                messages: $messages,
            )
        }
        #endif
    }
}

struct AllTheThings: View {
    @StateObject var webViewStore: WebViewStore
    @Binding var showView: Bool
    @Binding var guilds: [Thing]
    @Binding var chosenGuild: String?
    @Binding var channels: [Thing]
    @Binding var chosenChannel: String?
    @Binding var messages: [Message]
    @State var slider: Double = 1.0
    @State var slider2: Double = 0.30

    var body: some View {
        ZStack {
            VStack {
                if (showView) {
                    HStack {
                        ProgressView(value: webViewStore.estimatedProgress)
                            .padding()
                        Slider(value: $slider, in: 0.0...1.0) { v in
                            Task {
                                let _ = try? await runJS("document.body.style.zoom = v", ["v": slider])
                            }
                        }
                        Slider(value: $slider2, in: 0.00...1.00) { v in
                            webViewStore.webView.pageZoom = slider2
                        }
                    }
                }
                WebView(webView: webViewStore.webView)
                    .task {
                        if (showView == false) {return}
                        await vencord()
                        webViewStore.webView.allowsLinkPreview = true
                        if #available(iOS 16.4, *) {
                            webViewStore.webView.isInspectable = true
                        }
                        let rules = """
                    [{"trigger": {"url-filter": ".*", "resource-type": ["image", "font", "svg-document", "media", "other"]}, "action": {"type": "block"}, "if-domain": ["discord.com", "*.discord.com", "cdn.discordapp.com", "media.discordapp.net"], "load-context": ["top-frame"]}]
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
                        #if os(iOS)
                        webViewStore.webView.pageZoom = slider2
                        #endif
                        while !((try? await runJS("return \(store("Guild"))?.getGuildCount() > 0") as? Bool) ?? false) {
                            try? await Task.sleep(for: .seconds(1))
                        }
                        showView = false

                    }
                    .frame(width: showView ? nil : 0, height: showView ? 320 : 0)

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
                    if (guilds.isEmpty) {
                        _ = try! await runJS("""
                Vencord.Webpack.Common.FluxDispatcher.subscribe("MESSAGE_CREATE", (m) => {
                    if (!m.optimistic) {
                        window.webkit.messageHandlers.onMessage.postMessage({channelId: m.channelId, author: {name: m.message.author.username, avatar: m.message.author.avatar, id: m.message.author.id}, content: m.message.content, id: m.message.id, attachments: m.attachments, type: "MESSAGE_CREATE", edited: false})
                    }
                })
                Vencord.Webpack.Common.FluxDispatcher.subscribe("MESSAGE_UPDATE", (m) => {
                    window.webkit.messageHandlers.onMessage.postMessage({channelId: m.message.channel_id, author: {name: m.message.author.username, avatar: m.message.author.avatar, id: m.message.author.id}, content: m.message.content, id: m.message.id, attachments: m.attachments, type: "MESSAGE_UPDATE", edited: true})
                })
                Vencord.Webpack.Common.FluxDispatcher.subscribe("MESSAGE_DELETE", (m) => {
                    window.webkit.messageHandlers.onMessage.postMessage({channelId: m.channelId, id: m.id, type: "MESSAGE_DELETE"})
                })
                """)
                    }
                    try! await getGuilds()
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
        if (chosenChannel != nil) {
            _ = try! await runJS(
                "Vencord.Webpack.Common.NavigationRouter.transitionToGuild(guildId, channelId)",
                ["guildId": chosenGuild!, "channelId": chosenChannel!]
            )
        }
    }

    func getMessages() async throws {
        print("MESSAGES")
        await goToChannel()
        try? await Task.sleep(for: .seconds(1)) // todo: wait for CHANNEL_SELECT flux event
        if (chosenChannel == nil) {return}
        let lmessages = try! await runJS(
            "return \(store("Message")).getMessages(channel)._array.map(m=>{return {channelId: m.channel_id, author: {name: m.author.username, avatar: m.author.avatar, id: m.author.id}, content: m.content, id: m.id, attachments: m.attachments, edited: Boolean(m.editedTimestamp)}})",
            ["channel": chosenChannel!]
        )
        let rmessages = (lmessages as! [[String: Any]])
        messages = rmessages
            .map {
                try! Message($0)
            }
    }
}
