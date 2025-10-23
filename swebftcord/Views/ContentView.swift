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
    @State var guilds: [Thingy] = []
    @State var channels: [Thingy] = []
    @State var chosenGuild: String? = nil
    @State var chosenChannel: String? = nil
    @State var messages: [Message] = []
    @State var pingCountText: String = ""
    let reg = try! Regex("\\(([0-9]+)\\)")

    var body: some Scene {
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
    }
}

struct AllTheThings: View {
    @StateObject var webViewStore: WebViewStore
    @Binding var showView: Bool
    @Binding var guilds: [Thingy]
    @Binding var chosenGuild: String?
    @Binding var channels: [Thingy]
    @Binding var chosenChannel: String?
    @Binding var messages: [Message]
    @State var slider: Double = 1.0
    @State var slider2: Double = 0.30
    @State var started: Bool = false

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

                    WebView(webView: webViewStore.webView)
                        .task {
                            if started {return}
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
                            started = true

                        }
                        .frame(width: showView ? nil : 0, height: showView ? 320 : 0)
                }
            }
            if (!showView) {
                NavigationSplitView {
                    List(
                        guilds,
                        children: \.children,
                        selection: $chosenGuild
                    ) { i in
                        Text(i.name)
                    }
                    .refreshable {
                        try! await getGuilds()
                    }
                } content: {
                    if (chosenGuild != nil) {
                        List(channels, children: \.children, selection: $chosenChannel) { i in
                            Text(i.name)
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
                            chosenGuild: chosenGuild,
                            getMessages: getMessages,
                            runJS: runJS
                        )
                        .scenePadding(.all)
                    }
                }
                .task {
                    if (guilds.isEmpty) {
                        _ = try! await runJS("""
                clean = (m) => JSON.parse(JSON.stringify(m));
                Vencord.Webpack.Common.FluxDispatcher.subscribe("MESSAGE_CREATE", (m) => {
                    if (m.optimistic) {return}
                    m.message.channelId = m.channelId;
                    m.message.edited = false;
                    m.message.type = "MESSAGE_CREATE";
                    window.webkit.messageHandlers.onMessage.postMessage(clean(m.message))
                })
                Vencord.Webpack.Common.FluxDispatcher.subscribe("MESSAGE_UPDATE", (m) => {
                    m.message.channelId = m.message.channel_id;
                    m.message.attachments = m.attachments;
                    m.message.edited = true;
                    m.message.type = "MESSAGE_UPDATE";
                    window.webkit.messageHandlers.onMessage.postMessage(clean(m.message))
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
        .toolbar {
            Button("WebView", systemImage: "safari") {
                showView.toggle()
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
        let mguilds: [Thing] = (lguilds as! [[String: String]])
            .map { try! .init($0) }
        let rstructure = try await runJS("return JSON.parse(JSON.stringify(\(store("SortedGuild")).getCompatibleGuildFolders()))") as! [[String: Any]]
        let structure: [GuildFolderData] = rstructure.map { try! .init($0) }
        guilds.removeAll()
        for item in structure {
            if item.folderId == nil {
                guilds.append(contentsOf:
                                mguilds.filter { $0.id == item.guildIds[0] }
                    .map { Thingy(name: $0.name, id: $0.id) }
                )
            } else {
                guilds
                    .append(
                        .init(
                            name: item.folderName ?? "",
                            id: UUID().uuidString,
                            children: item.guildIds.compactMap { i in
                                if let h = mguilds.first(where: { $0.id == i}) {
                                    return .init(name: h.name, id: i)
                                }
                                return .none
                            }
                        )
                    )
            }
        }
        guilds.insert(.init(name: "DMs", id: "@me"), at: 0)
        guilds.insert(.init(name: "Favorites", id: "@favorites"), at: 1)
    }

    func getChannels(_ guildId: String) async throws {
        let lchannels: [[String: String]]
        if (guildId == "@me") {
            lchannels = try await runJS("""
                channels = \(store("PrivateChannelSort")).getSortedChannels()[1].map(i=>\(store("Channel")).getChannel(i.channelId));
                return channels.map(i=>{return {name: (i.name || (i.recipients?.map(\(store("User")).getUser).map(i=>i.username).join(", ")) || i.id), id: i.id}});
                """) as! [[String: String]]
            channels = lchannels.map { .init(name: $0["name"]!, id: $0["id"]!) }
        } else {
            lchannels = (try await runJS(
                "return \(store("GuildChannel")).getChannels(guildId).SELECTABLE.map(i=>i.channel).map(i=>{return {name: i.name, id: i.id}})",
                ["guildId": guildId]
            ) as! [[String: String]])
            let chdata = lchannels.map { Thing(name: $0["name"]!, id: $0["id"]!) }
            let order = try await runJS("""
                c = Vencord.Webpack.findStore("GuildCategoryStore").getCategories(guildId)
                b = Object.keys(c).filter(i=>i!="_categories").map(i=>{return {index: c._categories.filter(j=>j.channel.id==i)[0]?.index ?? -1, id: i, name: c._categories.filter(j=>j.channel.id==i)[0]?.channel.name, channels: c[i].map(j=>{return {id: j.channel.id, index: j.index}}).map(j=>j.id)}}).reduce((arr, j)=>arr.concat(j), []).sort((i,j)=>(i.index>j.index))
                return b
                """, ["guildId": guildId]) as! [[String: Any]]
            channels = order.map { .init($0, chdata) }
        }
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
            "return \(store("Message")).getMessages(channel)._array.map(i=>{i['channelId']=channel; i['edited'] = Boolean(i.editedTimestamp); i['message_reference'] = i['messageReference']; return i}).map(JSON.stringify).map(JSON.parse)",
            ["channel": chosenChannel!]
        )
        let rmessages = (lmessages as! [[String: Any]])
        messages = rmessages
            .map {
                try! Message($0)
            }
    }
}
