//
//  ViewController.swift
//  extend-and-override-ios
//
//  Created by HERNANDEZ ARQUES Carlos Felipe on 3/3/17.
//  Copyright © 2017 charques. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    var webView: WKWebView!
    var progressView: UIProgressView?
    var backButton = UIButton()
    var forwardButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        createComponents()
        
        loadURL()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
        case "loading":
            // If you have back and forward buttons, then here is the best time to enable it
            backButton.isEnabled = webView.canGoBack
            forwardButton.isEnabled = webView.canGoForward
            
        case "estimatedProgress":
            // If you are using a `UIProgressView`, this is how you update the progress
            progressView?.isHidden = webView.estimatedProgress == 1
            progressView?.progress = Float(webView.estimatedProgress)
            
        default:
            break
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // -----------------------------------
    // WKNavigationDelegate methods
    // -----------------------------------
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        // Called when the web view begins to receive web content.
        print("webView didCommit", navigation)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        // Called when web content begins to load in a web view.
        print("webView didStartProvisionalNavigation", navigation)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // Called when a web view receives a server redirect.
        print("webView didReceiveServerRedirectForProvisionalNavigation", navigation)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("webView didFinish", navigation)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Called when an error occurs while the web view is loading content.
        print("webView didFailProvisionalNavigation", navigation, error)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        // Called when an error occurs during navigation.
        print("webView didFail", navigation, error)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView runJavaScriptAlertPanelWithMessage", message)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        print("webView runJavaScriptConfirmPanelWithMessage", message)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("webView runJavaScriptTextInputPanelWithPrompt", prompt)
    }
    
    // -----------------------------------
    // Create view methods
    // -----------------------------------
    func createComponents() {
        // Create WKWebView in code, because IB cannot add a WKWebView directly
        webView = WKWebView()
        webView.frame = CGRect(x: 0, y: 70, width: 375, height: 637)
        view.addSubview(webView)
        
        // Create Progress View Control
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.default)
        progressView?.frame = CGRect(x: 0, y: 0, width: 375, height: 10)
        view.addSubview(progressView!)
        
        // Create Buttons
        backButton = UIButton(type: UIButtonType.roundedRect)
        backButton.frame = CGRect(x: 0, y: 25, width: 100, height: 40)
        backButton.setTitle("Back",for: .normal)
        backButton.layer.cornerRadius = 4
        backButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        backButton.tag = 1;
        backButton.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
        forwardButton = UIButton(type: UIButtonType.roundedRect)
        forwardButton.frame = CGRect(x: 275, y: 25, width: 100, height: 40)
        forwardButton.setTitle("Forward",for: .normal)
        forwardButton.layer.cornerRadius = 4
        forwardButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        forwardButton.tag = 2;
        forwardButton.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
        view.addSubview(backButton)
        view.addSubview(forwardButton)
        
        webView.uiDelegate = self
        
        // when any web page navigation happens, please tell me.
        webView.navigationDelegate = self
        
        webView.evaluateJavaScript("navigator.userAgent") { (result, error) -> Void in
            print("User-Agent: \(result)")
        }
        
        // Observers UI Delegate
        let webViewKeyPathsToObserve = ["loading", "estimatedProgress"]
        for keyPath in webViewKeyPathsToObserve {
            webView.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }
    }
    
    func buttonAction(sender: UIButton!) {
        let btnsendtag: UIButton = sender
        print("btnsendtag.tag", btnsendtag.tag)
        switch btnsendtag.tag {
        case 1:
            webView.goBack()
            
        case 2:
            webView.goForward()
            
        default:
            break
        }
    }
    
    func loadURL() {
        let urlString = "https://extend-and-override-web.herokuapp.com/"
        guard let url = URL(string: urlString) else {return}
        let request = URLRequest(url:url)
        webView.load(request)
    }


}

