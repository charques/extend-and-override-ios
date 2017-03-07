//
//  ViewController.swift
//  extend-and-override-ios
//
//  Created by HERNANDEZ ARQUES Carlos Felipe on 3/3/17.
//  Copyright © 2017 charques. All rights reserved.
//

import UIKit
import WebKit

var myContext = 0

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {

    var webView: WKWebView!
    var progressView: UIProgressView?
    var backButton = UIButton()
    var forwardButton = UIButton()
    
    deinit {
        webView?.removeObserver(self, forKeyPath: "loading")
        webView?.removeObserver(self, forKeyPath: "title")
        webView?.removeObserver(self, forKeyPath: "estimatedProgress")
        webView?.removeObserver(self, forKeyPath: "canGoBack")
        webView?.removeObserver(self, forKeyPath: "canGoForward")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        createComponents()
        
        evaluateUserAgent()
        
        loadURL()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let keyPath = keyPath else { return }
        
        guard let change = change else { return }
        if context != &myContext {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switch keyPath {
        case "loading":
            backButton.isEnabled = webView.canGoBack
            forwardButton.isEnabled = webView.canGoForward
            
        case "title":
            if let title = change[NSKeyValueChangeKey.newKey] as? String {
                navigationItem.title = title
            }
            
        case "estimatedProgress":
            if let progress = (change[NSKeyValueChangeKey.newKey] as AnyObject).floatValue {
                progressView?.setProgress(progress, animated: true)
                progressView?.isHidden = progress == 1
            }
            
        case "canGoBack":
            if let canGoBack = (change[NSKeyValueChangeKey.newKey] as AnyObject).boolValue {
                backButton.isEnabled = canGoBack
            }
            
        case "canGoForward":
            if let canGoForward = (change[NSKeyValueChangeKey.newKey] as AnyObject).boolValue {
                forwardButton.isEnabled = canGoForward
            }
            
        default:
            break
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // -----------------------------------
    // WKScriptMessageHandler methods
    // -----------------------------------
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let sentData = message.body as! NSDictionary
        
        let command = sentData["cmd"] as! String
        var response = Dictionary<String,AnyObject>()
        
        // INCREMENT COMMAND
        if command == "increment"{
            guard var count = sentData["count"] as? Int else{
                return
            }
            count += 1
            response["count"] = count as AnyObject?
        }
        // END INCREMENT COMMAND
        
        let callbackString = sentData["callbackFunc"] as? String
        sendResponse(aResponse: response, callback: callbackString)
    }
    
    func sendResponse(aResponse:Dictionary<String,AnyObject>, callback:String?){
        guard let callbackString = callback else{
            return
        }
        guard let generatedJSONData = try? JSONSerialization.data(withJSONObject: aResponse, options: JSONSerialization.WritingOptions(rawValue: 0)) else{
            print("failed to generate JSON for \(aResponse)")
            return
        }
        
        webView.evaluateJavaScript("(\(callbackString)('\(NSString(data:generatedJSONData, encoding:String.Encoding.utf8.rawValue)!)'))") { (JSReturnValue:Any?, error:Error?) in

            if error != nil {
                let errorDescription = (error as! NSError).description
                print("returned value: \(errorDescription)")
            }
            else if JSReturnValue != nil{
                print("returned value: \(JSReturnValue!)")
            }
            else{
                print("no return from JS")
            }
        }
    }
    
    // -----------------------------------
    // WKNavigationDelegate methods
    // -----------------------------------
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        // webView:\(webView)
        print("didStartProvisionalNavigation:\(navigation)", terminator: "\n\n")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation) {
        print("didCommitNavigation:\(navigation)", terminator: "\n\n")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: (@escaping (WKNavigationActionPolicy) -> Void)) {
        print("decidePolicyForNavigationAction:\(navigationAction) decisionHandler:\(decisionHandler)", terminator: "\n\n")
        
        print("navigationType:\(navigationAction.navigationType.rawValue) request:\(navigationAction.request)", terminator: "\n\n")
        switch navigationAction.navigationType {
        case .linkActivated:
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
        default:
            break
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: (@escaping (WKNavigationResponsePolicy) -> Void)) {
        print("decidePolicyForNavigationResponse:\(navigationResponse) decisionHandler:\(decisionHandler)", terminator: "\n\n")
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("didReceiveAuthenticationChallenge:\(challenge) completionHandler:\(completionHandler)", terminator: "\n\n")
        
        switch (challenge.protectionSpace.authenticationMethod) {
        case NSURLAuthenticationMethodHTTPBasic:
            let alertController = UIAlertController(title: "Authentication Required", message: webView.url?.host, preferredStyle: .alert)
            weak var usernameTextField: UITextField!
            alertController.addTextField { textField in
                textField.placeholder = "Username"
                usernameTextField = textField
            }
            weak var passwordTextField: UITextField!
            alertController.addTextField { textField in
                textField.placeholder = "Password"
                textField.isSecureTextEntry = true
                passwordTextField = textField
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                completionHandler(.cancelAuthenticationChallenge, nil)
            }))
            alertController.addAction(UIAlertAction(title: "Log In", style: .default, handler: { action in
                guard let username = usernameTextField.text, let password = passwordTextField.text else {
                    completionHandler(.rejectProtectionSpace, nil)
                    return
                }
                let credential = URLCredential(user: username, password: password, persistence: URLCredential.Persistence.forSession)
                completionHandler(.useCredential, credential)
            }))
            present(alertController, animated: true, completion: nil)
        default:
            completionHandler(.rejectProtectionSpace, nil);
        }
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation) {
        print("didReceiveServerRedirectForProvisionalNavigation:\(navigation)", terminator: "\n\n")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        print("didFinishNavigation:\(navigation)", terminator: "\n\n")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        print("didFailNavigation:\(navigation) withError:\(error)", terminator: "\n\n")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        print("didFailProvisionalNavigation:\(navigation) withError:\(error)", terminator: "\n\n")
    }
    
    // -----------------------------------
    // WKUIDelegate methods
    // -----------------------------------
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (@escaping () -> Void)) {
        print("runJavaScriptAlertPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(completionHandler)", terminator: "\n\n")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (@escaping (Bool) -> Void)) {
        print("runJavaScriptConfirmPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(completionHandler)", terminator: "\n\n")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler(true)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        print("runJavaScriptTextInputPanelWithPrompt:\(prompt) defaultText:\(defaultText) initiatedByFrame:\(frame) completionHandler:\(completionHandler)", terminator: "\n\n")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: prompt, preferredStyle: .alert)
        weak var alertTextField: UITextField!
        alertController.addTextField { textField in
            textField.text = defaultText
            alertTextField = textField
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completionHandler(nil)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler(alertTextField.text)
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    // -----------------------------------
    // Create view methods
    // -----------------------------------
    
    func createContentController() -> WKUserContentController {
        let contentController = WKUserContentController();
        
        // Configure JS invokation after load
        let userScript = WKUserScript(
            source: "customLogo()",
            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: true
        )
        contentController.addUserScript(userScript)
        
        // Set JS callback handler
        contentController.add(
            self,
            name: "native"
        )
        return contentController
    }
    

    func createComponents() {
        // Create WKWebView in code
        let config = WKWebViewConfiguration()
        config.userContentController = createContentController()
        webView = WKWebView(frame: CGRect(x: 0, y: 70, width: 375, height: 637), configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        
        // Add observers
        let webViewKeyPathsToObserve = ["loading", "title", "estimatedProgress", "canGoBack", "canGoForward"]
        for keyPath in webViewKeyPathsToObserve {
            webView.addObserver(self, forKeyPath: keyPath, options: .new, context: &myContext)
        }
        
        // Create Progress View Control
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.default)
        progressView?.frame = CGRect(x: 0, y: 0, width: 375, height: 10)
        view.addSubview(progressView!)
        
        // Create back button
        backButton = UIButton(type: UIButtonType.roundedRect)
        backButton.frame = CGRect(x: 0, y: 25, width: 100, height: 40)
        backButton.setTitle("Back",for: .normal)
        backButton.layer.cornerRadius = 4
        backButton.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
        backButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        backButton.tag = 1
        backButton.isEnabled = false
        view.addSubview(backButton)
        
        // Create forward button
        forwardButton = UIButton(type: UIButtonType.roundedRect)
        forwardButton.frame = CGRect(x: 275, y: 25, width: 100, height: 40)
        forwardButton.setTitle("Forward",for: .normal)
        forwardButton.layer.cornerRadius = 4
        forwardButton.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
        forwardButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        forwardButton.tag = 2
        forwardButton.isEnabled = false
        view.addSubview(forwardButton)
    }
    
    func evaluateUserAgent() {
        webView.evaluateJavaScript("navigator.userAgent") { (result, error) -> Void in
            print("User-Agent: \(result)", terminator: "\n\n")
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
