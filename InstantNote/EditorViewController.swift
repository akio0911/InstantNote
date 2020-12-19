//
//  EditorViewController.swift
//  InstantNote
//
//  Created by Shotaro Maruyama on 2020/11/19.
//
//

import UIKit
import GoogleMobileAds
import MessageUI
import AdSupport
import AppTrackingTransparency
/**
 todo テスト用バナーID ca-app-pub-3940256099942544/2934735716
 
 ローディング表示...広告購入時のみ
 UIActivity実装...ボタン
 文字数表示...ラベル
 テーマカラー変更...セレクトボックス
 
 */

class EditorViewController: UIViewController,UIViewControllerTransitioningDelegate, GADBannerViewDelegate,MFMailComposeViewControllerDelegate {
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var textView: UITextView! {
        didSet { textView.delegate = self }
    }
    
    private let viewModel = EditorViewModel()
    
    private var banner = GADBannerView()
    
    private var textViewFrame:CGRect {
        var height:CGFloat = 0
        if(viewModel.isReceivedAd){
            height = self.view.frame.size.height - self.toolbar.frame.maxY - self.view.safeAreaInsets.bottom - banner.frame.size.height
        }else{
            height = self.view.frame.size.height - self.toolbar.frame.maxY - self.view.safeAreaInsets.bottom
        }
        return CGRect(x: self.toolbar.frame.origin.x,
                      y: self.toolbar.frame.maxY,
                      width: self.toolbar.frame.size.width,
                      height: height
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.userDefaults.register(defaults: ["isPurchasedInValidAd":false])
        banner.delegate = self
        // Do any additional setup after loading the view.
        self.toolbar.tintColor = UIColor.systemBlue
        self.toolbar.isTranslucent = true
        self.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.any, barMetrics: UIBarMetrics.default)
        self.toolbar.setShadowImage(UIImage(), forToolbarPosition: UIBarPosition.any)
        //キーボードサイズに変化があったときのメソッドを設定
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        //キーボードが閉じられたときのメソッドを設定
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // ツールバー生成
        let doneButtonBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 35))
        // スタイルを設定
        doneButtonBar.barStyle = UIBarStyle.default
        // 閉じるボタンを右に配置するためのスペース
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
        // 閉じるボタン
        let commitButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(dismissKeyboard))
        //セレクタモードボタン
        let onSelectModeButton = UIBarButtonItem(image: UIImage(named: "sellection"), style: .plain, target: self, action: #selector(onSelectMode))
        doneButtonBar.tintColor = UIColor.systemBlue
        doneButtonBar.isTranslucent = true
        doneButtonBar.setBackgroundImage(UIImage(), forToolbarPosition: UIBarPosition.any, barMetrics: UIBarMetrics.default)
        doneButtonBar.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
        doneButtonBar.setShadowImage(UIImage(), forToolbarPosition: UIBarPosition.any)
        // スペース、閉じるボタンを右側に配置
        doneButtonBar.items = [onSelectModeButton,spacer, commitButton]
        // textViewのキーボードにツールバーを設定
        textView.inputAccessoryView = doneButtonBar
        
        if(viewModel.isPurchasedInValidAd == false){
            requestAd()
        }
        
        if #available(iOS 14, *) {
            switch ATTrackingManager.trackingAuthorizationStatus {
            case .authorized:
                print("Allow Tracking")
                print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
            case .denied:
                print("😭拒否")
            case .restricted:
                print("🥺制限")
            case .notDetermined:
                showRequestTrackingAuthorizationAlert()
            @unknown default:
                fatalError()
            }
        } else {// iOS14未満
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                print("Allow Tracking")
                print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
            } else {
                print("🥺制限")
            }
        }
    }
    
    
    private func showRequestTrackingAuthorizationAlert() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                switch status {
                case .authorized:
                    //IDFA取得
                    print("IDFA: \(ASIdentifierManager.shared().advertisingIdentifier)")
                case .denied, .restricted, .notDetermined:
                    print("denied")
                @unknown default:
                    fatalError()
                }
            })
        }
    }
    
    private func requestAd(){
        banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"//テスト
        banner.rootViewController = self
        banner.load(GADRequest())
    }
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        if(viewModel.isReceivedAd == false){
            view.addSubview(banner)
            banner.frame.origin.y = toolbar.frame.maxY
            viewModel.isReceivedAd = true
            adjustTextViewFrameForAdSize()
        }
    }

    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        _ = initViewDidLayoutSubviews
    }
    
    lazy private var initViewDidLayoutSubviews: Void = {
        self.textView.frame = self.textViewFrame
        //バックグラウンドから復帰した時のメソッドを設定
        //キーボード起動による初回起動時のtextViewへのアクセスを避けるためここで定義
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }()
    
    private func adjustTextViewFrameForAdSize(){
        textView.frame.size.height -= banner.frame.size.height
        textView.frame.origin.y = banner.frame.maxY
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadBannerAd()
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with:coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.loadBannerAd()
        })
    }
    
    private func loadBannerAd() {
        // Step 2 - Determine the view width to use for the ad width.
        let frame = { () -> CGRect in
            // Here safe area is taken into account, hence the view frame is used
            // after the view has been laid out.
            if #available(iOS 11.0, *) {
                return view.frame.inset(by: view.safeAreaInsets)
            } else {
                return view.frame
            }
        }()
        let viewWidth = frame.size.width
        
        // Step 3 - Get Adaptive GADAdSize and set the ad view.
        // Here the current interface orientation is used. If the ad is being preloaded
        // for a future orientation change or different orientation, the function for the
        // relevant orientation should be used.
        banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        
        // Step 4 - Create an ad request and load the adaptive banner ad.
        banner.load(GADRequest())
    }
    
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if(self.textView.frame.size.height == textViewFrame.height){
                self.textView.frame.size.height = (textViewFrame.height + self.view.safeAreaInsets.bottom) - keyboardSize.height
            }
        }
    }
    
    @objc private func keyboardWillHide() {
        if (self.textView.frame.size.height != textViewFrame.height){
            self.textView.frame.size.height = textViewFrame.height
        }
    }
    
    @objc private func onSelectMode() {
        if (textView.text.isEmpty == false){
            if let startPosition = textView.position(from: textView.selectedTextRange!.start, offset: -1){
                textView.selectedTextRange = textView.textRange(from: startPosition, to: textView.position(from: textView.selectedTextRange!.start, offset: textView.selectedRange.length)!)
            }
        }
    }
    
    @objc private func willEnterForeground() {
        self.textView.becomeFirstResponder()
    }
    
    @IBAction private func copyText(_ sender: Any) {
        if (textView.text.isEmpty == false){
            noTitleAlert(message: "コピーしました", delay: 0.1)
        }
    }
    
    private func noTitleAlert(message:String, delay:Double){
        UIPasteboard.general.string = textView.text!
        let dialog: UIAlertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        // アラート表示
        self.present(dialog, animated: false, completion: {
            // アラートを閉じる
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                dialog.dismiss(animated: true, completion: nil)
            })
        })
    }
    
    @IBAction private func pasteText(_ sender: Any) {
        if let copiedText = UIPasteboard.general.string{
            textView.isScrollEnabled = false
            if(textView.selectedRange.length > 0){
                // 範囲選択されてれば選択範囲をコピー元テキストに置き換え
                let startCurorPosition = textView.selectedRange.location
                textView.text.replaceSubrange(Range(textView.selectedRange, in: textView.text)!, with: copiedText)
                textView.selectedRange.location = startCurorPosition + copiedText.count
                textViewDidChange(textView)
            }else{
                let selectedRange = textView.selectedTextRange!
                let cursorPosition = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
                let contents = NSMutableString(string:textView.text ?? "")
                contents.insert(copiedText, at: cursorPosition)
                textView.text = String(contents)
                if let newPosition = textView.position(from: selectedRange.start, offset: copiedText.count){
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                }
                textViewDidChange(textView)
            }
            textView.isScrollEnabled = true
        }
    }
    
    @IBAction private func moveToTrash(_ sender: Any) {
        if(textView.text!.isEmpty == false){
            registerUndo(text: viewModel.oldText)
            textView.text? = ""
        }
    }
    
    @IBAction private func undo(_ sender: Any) {
        if(viewModel.textViewUndoManager.canUndo){
            viewModel.textViewUndoManager.undo()
            viewModel.oldText = textView.text
        }
    }
    
    @IBAction private func redo() {
        if(viewModel.textViewUndoManager.canRedo){
            viewModel.textViewUndoManager.redo()
            viewModel.oldText = textView.text
        }
    }

    private func registerUndo(text: String) {
        if (viewModel.textViewUndoManager.isUndoRegistrationEnabled) {
            viewModel.textViewUndoManager.registerUndo(withTarget: self, handler: { _ in
                if let currentText = self.textView.text { self.registerUndo(text: currentText) }
                self.textView.text = text
            })
        }
    }
    
    @IBAction private func bigger(_ sender: Any) {
        textView.increaseFontSize()
    }
    @IBAction private func smaller(_ sender: Any) {
        textView.decreaseFontSize()
        
    }
    
    @IBAction private func tapInfoButton(_ sender: Any) {
        let infoVC = self.storyboard?.instantiateViewController(identifier: "info-modal") as! InfoViewController
        infoVC.modalPresentationStyle = .custom
        infoVC.transitioningDelegate = self
        infoVC.infoMethodDelegate = self
        
        present(infoVC, animated: true, completion: nil)
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return InfoUIPresentationController(presentedViewController: presented, presenting: presenting)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            print("Email Send Cancelled")
            break
        case .saved:
            print("Email Saved as a Draft")
            break
        case .sent:
            print("Email Sent Successfully")
            break
        case .failed:
            print("Email Send Failed")
            break
        default:
            break
        }
        controller.dismiss(animated: true, completion: nil)
    }
    
}

extension UITextView {
    func increaseFontSize () {
        if((self.font?.pointSize)! < 42){
            self.font =  UIFont.systemFont(ofSize: (self.font?.pointSize)!+4)
        }
        
    }
    func decreaseFontSize () {
        if((self.font?.pointSize)! > 12){
            self.font =  UIFont.systemFont(ofSize: (self.font?.pointSize)!-4)
        }
    }
}

extension EditorViewController: UITextViewDelegate{
    func textViewDidChange(_ textView: UITextView) {
        if (textView.markedTextRange == nil) {
            registerUndo(text: viewModel.oldText)
            viewModel.oldText = textView.text
        }
    }
}

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return self.layer.borderWidth
        }
        set {
            self.layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            return UIColor(cgColor: self.layer.borderColor!)
        }
        set {
            self.layer.borderColor = newValue?.cgColor
        }
    }
    
}


extension EditorViewController: infoMethodDelegate {
    func sendMail() {
        //メールを送信できるかチェック
        if MFMailComposeViewController.canSendMail()==false {
            print("can not use mailer")
            return
        }
        
        let version = UIDevice.current.systemVersion
        
        let mailViewController = MFMailComposeViewController()
        let toRecipients = ["wantailang.develop@gmail.com"] //Toのアドレス指定
        
        mailViewController.mailComposeDelegate = self
        
        mailViewController.setSubject("InstantNoteへのご意見・ご要望")
        mailViewController.setToRecipients(toRecipients) //Toアドレスの表示
        mailViewController.setMessageBody("頂いたメールは開発者が責任を持って精査し３日以内に宛先のメールアドレスから返信致します。\n以下に本文をお書きください。　\n*****\n\n\n*****\niOS version:\(version)\nご利用端末:\(UIDevice.current.model)", isHTML: false)
        present(mailViewController, animated: true, completion: nil)
    }
}
