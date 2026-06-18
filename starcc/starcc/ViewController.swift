//
//  ViewController.swift
//  starcc
//
//  Created by 무노스 on 2020/04/01.
//  Copyright © 2020 무노스. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController {

    var webView: WKWebView!

    let jsPolyfill = """
    window.JSModel = {
        showAlert: function(t, m) {
            window.webkit.messageHandlers.jsInterface.postMessage({action:'showAlert', title:t, message:m});
        },
        getName: function() { return 'DH'; },
        jsCall: function() {
            window.webkit.messageHandlers.jsInterface.postMessage({action:'jsCall'});
        }
    };
    """

    override func loadView() {
        let userScript = WKUserScript(source: jsPolyfill, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        let contentController = WKUserContentController()
        contentController.add(self, name: "jsInterface")
        contentController.addUserScript(userScript)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.applicationIconBadgeNumber = 0
        loadWebPage("https://www.starcc.net/Mobile/")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func loadWebPage(_ url: String) {
        guard let myUrl = URL(string: url) else { return }
        webView.load(URLRequest(url: myUrl))
    }
}

extension ViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("callUserInfoUpdate('', 'Y')", completionHandler: nil)
    }
}

extension ViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let popupWebView = WKWebView(frame: UIScreen.main.bounds, configuration: configuration)
        popupWebView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popupWebView.navigationDelegate = self
        popupWebView.uiDelegate = self
        view.addSubview(popupWebView)
        return popupWebView
    }

    func webViewDidClose(_ webView: WKWebView) {
        webView.removeFromSuperview()
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "취소", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "jsInterface",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }

        switch action {
        case "showAlert":
            let title = body["title"] as? String ?? ""
            let msg = body["message"] as? String ?? ""
            DispatchQueue.main.async {
                let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default))
                self.present(alert, animated: true)
            }
        case "jsCall":
            webView.evaluateJavaScript("jsReturn('JS call success!!')", completionHandler: nil)
        default:
            break
        }
    }
}
