//
//  QuoteFloorViewController.swift
//  Stage1st
//
//  Created by Zheng Li on 7/12/15.
//  Copyright (c) 2015 Renaissance. All rights reserved.
//

import WebKit
import Crashlytics
import CocoaLumberjack
import JTSImageViewController
import Photos

class QuoteFloorViewController: UIViewController, ImagePresenter, UserPresenter, ContentPresenter {
    let viewModel: QuoteFloorViewModel

    lazy var webView: WKWebView = {
        WKWebView(frame: .zero, configuration: self.sharedConfiguration())
    }()

    lazy var webViewScriptMessageHandler: GeneralScriptMessageHandler = {
        GeneralScriptMessageHandler(delegate: self)
    }()

    var presentType: PresentType = .none {
        didSet {
            switch presentType {
            case .none:
                Crashlytics.sharedInstance().setObjectValue("QuoteViewController", forKey: "lastViewController")
            case .image:
                Crashlytics.sharedInstance().setObjectValue("ImageViewController", forKey: "lastViewController")
            default:
                break
            }
        }
    }

    init(viewModel: QuoteFloorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        automaticallyAdjustsScrollViewInsets = false

        webView.navigationDelegate = self
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
        webView.scrollView.delegate = self
        webView.isOpaque = false

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: .UIApplicationWillEnterForeground,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceivePaletteChangeNotification(_:)),
                                               name: .APPaletteDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveUserBlockStatusDidChangedNotification(_:)),
                                               name: .UserBlockStatusDidChangedNotification,
                                               object: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DDLogInfo("[QuoteFloorVC] Dealloc Begin")
        NotificationCenter.default.removeObserver(self)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "stage1st")
        webView.scrollView.delegate = nil
        webView.stopLoading()
        DDLogInfo("[QuoteFloorVC] Dealloced")
    }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
            make.leading.trailing.equalTo(self.view)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        presentType = .none

        // defer from initializer to here to make sure navigationController exist (i.e. self be added to navigation stack)
        // FIXME: find a way to make sure this only called once. Prefer this not work.
        if let colorPanRecognizer = (navigationController?.delegate as? NavigationControllerDelegate)?.colorPanRecognizer {
            webView.scrollView.panGestureRecognizer.require(toFail: colorPanRecognizer)
        }

        didReceivePaletteChangeNotification(nil)

        tryToReloadWKWebViewIfPageIsBlankDueToWebKitProcessTerminated()
    }

    func applicationWillEnterForeground() {
        DDLogDebug("[QuoteFloorVC] \(self) will enter foreground begin")
        tryToReloadWKWebViewIfPageIsBlankDueToWebKitProcessTerminated()
        DDLogDebug("[QuoteFloorVC] \(self) will enter foreground end")
    }
}

// MARK: - Actions
extension QuoteFloorViewController {
    override func didReceivePaletteChangeNotification(_ notification: Notification?) {
        view.backgroundColor = ColorManager.shared.colorForKey("content.background")
        webView.backgroundColor = ColorManager.shared.colorForKey("content.webview.background")

        setNeedsStatusBarAppearanceUpdate()

        if notification != nil {
            webView.loadHTMLString(viewModel.generatePage(with: viewModel.floors), baseURL: viewModel.baseURL)
        }
    }

    open func didReceiveUserBlockStatusDidChangedNotification(_: Notification?) {
        webView.loadHTMLString(viewModel.generatePage(with: viewModel.floors), baseURL: viewModel.baseURL)
    }
}

// MARK:
extension QuoteFloorViewController {
    func sharedConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(webViewScriptMessageHandler, name: "stage1st")
        configuration.userContentController = userContentController
        return configuration
    }
}

// MARK: - WKScriptMessageHandler
extension QuoteFloorViewController: WebViewEventDelegate {
    func generalScriptMessageHandler(_: GeneralScriptMessageHandler, actionButtonTappedFor _: Int) {
        //        actionButtonTapped(for: floorID)
    }
}

// MARK: JTSImageViewControllerInteractionsDelegate
extension QuoteFloorViewController: JTSImageViewControllerInteractionsDelegate {
    func imageViewerDidLongPress(_ imageViewer: JTSImageViewController!, at rect: CGRect) {
        let imageActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        imageActionSheet.addAction(UIAlertAction(title: NSLocalizedString("ImageViewController.ActionSheet.Save", comment: "Save"), style: .default, handler: { _ in
            DispatchQueue.global(qos: .background).async {
                PHPhotoLibrary.requestAuthorization { status in
                    guard case .authorized = status else {
                        DDLogError("No auth to access photo library")
                        return
                    }

                    let imageData = imageViewer.imageData
                    guard imageData != nil else {
                        DDLogError("Image data is nil")
                        return
                    }

                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCreationRequest.forAsset().addResource(with: .photo, data: imageData!, options: nil)
                    }, completionHandler: { _, error in
                        if let error = error {
                            DDLogError("\(error)")
                        }
                    })
                }
            }
        }))

        imageActionSheet.addAction(UIAlertAction(title: NSLocalizedString("ImageViewController.ActionSheet.CopyURL", comment: "Copy URL"), style: .default, handler: { _ in
            UIPasteboard.general.string = imageViewer.imageInfo.imageURL.absoluteString
        }))

        imageActionSheet.addAction(UIAlertAction(title: NSLocalizedString("ContentViewController.ActionSheet.Cancel", comment: "Cancel"), style: .cancel, handler: nil))

        imageActionSheet.popoverPresentationController?.sourceView = imageViewer.view
        imageActionSheet.popoverPresentationController?.sourceRect = rect
        imageViewer.present(imageActionSheet, animated: true, completion: nil)
    }
}

// MARK: JTSImageViewControllerOptionsDelegate
extension QuoteFloorViewController: JTSImageViewControllerOptionsDelegate {
    func alphaForBackgroundDimmingOverlay(inImageViewer _: JTSImageViewController!) -> CGFloat {
        return 0.3
    }
}

// MARK: WKNavigationDelegate
extension QuoteFloorViewController: WKNavigationDelegate {

    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if url.absoluteString.hasPrefix("file://") {
            if url.absoluteString.hasSuffix("html") {
                decisionHandler(.allow)
                return
            }
        }

        // Image URL opened in image Viewer
        if url.absoluteString.hasSuffix(".jpg") || url.absoluteString.hasSuffix(".gif") || url.absoluteString.hasSuffix(".png") {
            Answers.logCustomEvent(withName: "Inspect Image", customAttributes: [
                "type": "hijack",
                "source": "QuoteFloor",
            ])
            showImageViewController(transitionSource: .offScreen, imageURL: url)
            decisionHandler(.cancel)
            return
        }

        if AppEnvironment.current.serverAddress.hasSameDomain(with: url) {
            // Open as S1 topic
            if let topic = S1Parser.extractTopicInfo(fromLink: url.absoluteString) {
                var topic = topic
                if let tracedTopic = viewModel.dataCenter.traced(topicID: topic.topicID.intValue) {
                    let lastViewedPage = topic.lastViewedPage
                    topic = tracedTopic.copy() as! S1Topic
                    if lastViewedPage != nil {
                        topic.lastViewedPage = lastViewedPage
                    }
                }

                Answers.logCustomEvent(withName: "Open Topic Link", customAttributes: [
                    "source": "QuoteFloor",
                ])
                showContentViewController(topic: topic)
                decisionHandler(.cancel)
                return
            }
        }

        // Fallback Open link
        let alertViewController = UIAlertController(title: NSLocalizedString("ContentViewController.WebView.OpenLinkAlert.Title", comment: ""),
                                                    message: url.absoluteString,
                                                    preferredStyle: .alert)

        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("ContentViewController.WebView.OpenLinkAlert.Cancel", comment: ""),
                                                    style: .cancel,
                                                    handler: nil))

        alertViewController.addAction(UIAlertAction(title: NSLocalizedString("ContentViewController.WebView.OpenLinkAlert.Open", comment: ""),
                                                    style: .default,
                                                    handler: { [weak self] _ in
                                                        guard let strongSelf = self else { return }
                                                        strongSelf.presentType = .background
                                                        DDLogDebug("[ContentVC] Open in Safari: \(url)")

                                                        if !UIApplication.shared.openURL(url) {
                                                            DDLogWarn("Failed to open url: \(url)")
                                                        }
        }))

        present(alertViewController, animated: true, completion: nil)

        DDLogWarn("no case match for url: \(url), fallback cancel")
        decisionHandler(.cancel)
        return
    }

    func webViewWebContentProcessDidTerminate(_: WKWebView) {
        DDLogError("[QuoteFloor] \(#function)")
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            let computedOffset: CGFloat = strongSelf.topPositionOfMessageWithId(strongSelf.viewModel.centerFloorID) - 32
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                webView.evaluateJavaScript("$('html, body').animate({ scrollTop: \(computedOffset)}, 0);", completionHandler: nil)
            }
        }
    }
}

// MARK: UIScrollViewDelegate
extension QuoteFloorViewController: UIScrollViewDelegate {
    // To fix bug in WKWebView
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal
    }
}

// MARK: - Helper
extension QuoteFloorViewController {
    func topPositionOfMessageWithId(_ elementID: Int) -> CGFloat {
        if let rect = webView.s1_positionOfElement(with: "postmessage_\(elementID)") {
            return rect.minY
        } else {
            DDLogError("[QuoteFloorVC] Touch element ID: \(elementID) not found.")
            return 0.0
        }
    }

    fileprivate func tryToReloadWKWebViewIfPageIsBlankDueToWebKitProcessTerminated() {
        guard let title = webView.title, title != "" else {
            webView.loadHTMLString(viewModel.generatePage(with: viewModel.floors), baseURL: viewModel.baseURL)
            return
        }
    }
}

// MARK: - Style
extension QuoteFloorViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ColorManager.shared.isDarkTheme() ? .lightContent : .default
    }
}
