import UIKit
import WebKit

/// Launcher settings configured in the HubChat panel.
public struct HubChatSettings {
    public let color: UIColor
    public let isRight: Bool
    public let launcherText: String?
    public let launcherImage: URL?
    public let title: String?
    public let subtitle: String?

    /// Same contrast rule as widget.js.
    var onColor: UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        func channel(_ v: CGFloat) -> CGFloat { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
        return luminance > 0.45 ? UIColor(red: 11 / 255, green: 18 / 255, blue: 32 / 255, alpha: 1) : .white
    }

    init(json: [String: Any]) {
        func text(_ key: String) -> String? {
            guard let value = json[key] as? String, !value.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return value
        }
        color = UIColor(hex: json["color"] as? String ?? "#2563eb")
        isRight = (json["position"] as? String) == "right"
        launcherText = text("launcher_text")
        launcherImage = text("launcher_image").flatMap(URL.init(string:))
        title = text("title")
        subtitle = text("subtitle")
    }
}

public extension Notification.Name {
    static let hubChatUnreadChanged = Notification.Name("HubChatUnreadChanged")
    static let hubChatSettingsLoaded = Notification.Name("HubChatSettingsLoaded")
}

/// Entry point: `HubChat.configure(widgetKey: "hc_...")` in AppDelegate, then
/// `HubChat.showLauncher(in: window)` or `HubChat.open()` from your own button.
public final class HubChat: NSObject {
    public static let shared = HubChat()

    public private(set) var widgetKey = ""
    public private(set) var baseURL = URL(string: "https://widget.hubchat.ir")!
    public private(set) var settings: HubChatSettings?
    public private(set) var unread = 0 { didSet { NotificationCenter.default.post(name: .hubChatUnreadChanged, object: self) } }
    public private(set) var isOpen = false

    /// Called for every widget event (ready, close, unread) with its payload.
    public var onEvent: ((String, [String: Any]) -> Void)?

    var widgetURL: URL { baseURL.appendingPathComponent("widget").appendingPathComponent(widgetKey) }

    /// Kept alive across opens so the conversation and unread events keep running.
    private(set) lazy var webView: WKWebView = makeWebView()
    private var loaded = false
    private weak var presented: UIViewController?

    public static func configure(widgetKey: String, baseURL: URL? = nil) {
        shared.widgetKey = widgetKey
        if let baseURL { shared.baseURL = baseURL }
        shared.fetchSettings()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { shared.load() }
    }

    /// Presents the chat panel full screen over the top-most view controller.
    public static func open(from viewController: UIViewController? = nil) {
        shared.load()
        guard shared.presented == nil, let host = viewController ?? UIApplication.shared.hubChatTopViewController else { return }
        let panel = HubChatViewController()
        panel.modalPresentationStyle = .fullScreen
        shared.presented = panel
        host.present(panel, animated: true)
    }

    public static func close() {
        shared.presented?.dismiss(animated: true)
    }

    /// Adds the floating launcher to a window or view.
    @discardableResult
    public static func showLauncher(in view: UIView, bottomOffset: CGFloat = 0) -> HubChatLauncherButton {
        let button = HubChatLauncherButton()
        button.install(in: view, bottomOffset: bottomOffset)
        return button
    }

    func load() {
        guard !loaded, !widgetKey.isEmpty else { return }
        loaded = true
        webView.load(URLRequest(url: widgetURL))
    }

    func didOpen() {
        isOpen = true
        unread = 0
        command("open")
    }

    func didClose() {
        isOpen = false
        presented = nil
        command("closed")
    }

    private func command(_ type: String) {
        webView.evaluateJavaScript("window.postMessage({source:'hubchat-loader',type:'\(type)'},'*');")
    }

    private func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let bridge = "window.HubChatBridge={postMessage:function(m){window.webkit.messageHandlers.hubchat.postMessage(m);}};"
        configuration.userContentController.addUserScript(WKUserScript(source: bridge, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        configuration.userContentController.add(WeakScriptHandler(self), name: "hubchat")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.957, green: 0.965, blue: 0.98, alpha: 1)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        return webView
    }

    private func fetchSettings() {
        URLSession.shared.dataTask(with: widgetURL.appendingPathComponent("config")) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let raw = json["settings"] as? [String: Any] else { return }
            DispatchQueue.main.async {
                self.settings = HubChatSettings(json: raw)
                NotificationCenter.default.post(name: .hubChatSettingsLoaded, object: self)
            }
        }.resume()
    }

    fileprivate func receive(_ raw: String) {
        guard let data = raw.data(using: .utf8),
              let message = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              message["source"] as? String == "hubchat",
              let type = message["type"] as? String else { return }

        switch type {
        case "close": HubChat.close()
        case "ready": if isOpen { command("open") }
        case "unread": if !isOpen { unread = (message["count"] as? Int) ?? unread + 1 }
        default: break
        }
        onEvent?(type, message)
    }
}

/// Avoids the retain cycle WKUserContentController creates with its handlers.
private final class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var target: HubChat?
    init(_ target: HubChat) { self.target = target }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        if let body = message.body as? String { target?.receive(body) }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value)
        self.init(red: CGFloat((value >> 16) & 0xff) / 255, green: CGFloat((value >> 8) & 0xff) / 255, blue: CGFloat(value & 0xff) / 255, alpha: 1)
    }
}

extension UIApplication {
    var hubChatTopViewController: UIViewController? {
        let window = connectedScenes.compactMap { ($0 as? UIWindowScene)?.windows.first(where: \.isKeyWindow) }.first
        var top = window?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}
