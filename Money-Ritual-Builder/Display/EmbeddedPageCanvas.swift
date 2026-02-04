import SwiftUI
import WebKit

struct EmbeddedPageCanvas: UIViewRepresentable {
    let pageAddress: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.processPool = WKProcessPool()

        let canvasView = WKWebView(frame: .zero, configuration: config)
        canvasView.navigationDelegate = context.coordinator
        canvasView.allowsBackForwardNavigationGestures = true

        canvasView.backgroundColor = .black
        canvasView.isOpaque = true
        canvasView.scrollView.backgroundColor = .black
        canvasView.scrollView.contentInsetAdjustmentBehavior = .automatic
        canvasView.scrollView.bounces = false
        canvasView.scrollView.alwaysBounceVertical = false
        canvasView.scrollView.alwaysBounceHorizontal = false
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        return canvasView
    }

    func updateUIView(_ canvasView: WKWebView, context: Context) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            canvasView.frame = window.bounds
        }

        guard
            let encoded = pageAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: encoded)
        else { return }

        if canvasView.url != url {
            let request = URLRequest(url: url)
            canvasView.load(request)
        }
    }

    func makeCoordinator() -> PageLoadDelegate {
        PageLoadDelegate()
    }

    final class PageLoadDelegate: NSObject, WKNavigationDelegate {
        func webView(_ canvasView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("Navigation started: \(canvasView.url?.absoluteString ?? "")")
        }

        func webView(_ canvasView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Navigation completed")
            DispatchQueue.main.async {
                canvasView.scrollView.contentInset = .zero
                canvasView.scrollView.scrollIndicatorInsets = .zero
                canvasView.setNeedsLayout()
                canvasView.layoutIfNeeded()
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }

        func webView(_ canvasView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Navigation failed: \(error.localizedDescription)")
        }
    }
}
