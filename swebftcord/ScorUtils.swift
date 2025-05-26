//
//  ScorUtils.swift
//  menuscor
//
//  Created by mugman on 05/2025.
//


import WebKit

func downloadItem(_ url: String) async -> String {
    let injectorURL: URL = .init(string: url)!
    let req = URLRequest(url: injectorURL)
    let (data, _) = try! await URLSession.shared.data(for: req)
    return String(data: data, encoding: .utf8)!
}

func loadCSS(_ url: String) async -> WKUserScript {
    let contentCSS = await downloadItem(url)
    return await loadCSS(contentCSS: contentCSS)
}

func loadCSS(contentCSS: String) async -> WKUserScript {
    let b64CSS = contentCSS.data(using: .utf8)?.base64EncodedString()
    /// https://medium.com/@mahdi.mahjoobi/injection-css-and-javascript-in-wkwebview-eabf58e5c54e
    let css = "javascript:(function() {var parent = document.getElementsByTagName('head').item(0); var style = document.createElement('style'); style.type = 'text/css'; style.innerHTML = window.atob('\(b64CSS ?? "")'); parent.appendChild(style)})()"
    return await createUserScript(css, when: .atDocumentEnd, forMainFrame: true)
}

func loadJS(_ url: String) async -> WKUserScript {
    let injectorJS = await downloadItem(url)
    return await createUserScript(injectorJS, when: .atDocumentStart)
}

func createUserScript(_ source: String, when: WKUserScriptInjectionTime, forMainFrame: Bool = false) async -> WKUserScript {
    let script = await WKUserScript(
        source: source,
        injectionTime: when,
        forMainFrameOnly: forMainFrame
    )
    return script
}
