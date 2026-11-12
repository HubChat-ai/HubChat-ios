import UIKit
import WebKit

/// Full-screen chat panel hosting the shared widget WebView.
final class HubChatViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private var webView: WKWebView { HubChat.shared.webView }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = webView.backgroundColor
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        HubChat.shared.didOpen()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            webView.removeFromSuperview()
            HubChat.shared.didClose()
        }
    }

    /// Links to other hosts (Telegram, phone, mail...) open outside the panel.
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, action.navigationType == .linkActivated || action.targetFrame == nil, url.host != HubChat.shared.widgetURL.host {
            UIApplication.shared.open(url)
            return decisionHandler(.cancel)
        }
        decisionHandler(.allow)
    }

    /// window.open / target=_blank.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url { UIApplication.shared.open(url) }
        return nil
    }
}
