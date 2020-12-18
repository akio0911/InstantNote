//
//  InfoViewController.swift
//  InstantNote
//
//  Created by Shotaro Maruyama on 2020/11/29.
//  
//

import UIKit
import SwiftyStoreKit

protocol infoMethodDelegate: class {
    func sendMail()
}

class InfoViewController: UIViewController {
    
    let PRODUCT_ID = "INSTANTNOTE749196100223"
    
    // MARK:　- delegate に使うプロパティは、循環参照を防止するために weak キーワードをつける
    weak var infoMethodDelegate: infoMethodDelegate?
    
    lazy var mailSendButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("ご意見・ご要望はこちら", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        button.addTarget(self, action: #selector(self.clickSendMailButton(sender:)), for: .touchUpInside)
        button.sizeToFit()
        button.borderWidth = 2
        button.borderColor = UIColor.blue
        
        return button
    }()
    
    lazy var purchaseButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("広告非表示", for: .normal)
        button.setTitleColor(UIColor.blue, for: .normal)
        button.addTarget(self, action: #selector(self.purchase(sender:)), for: .touchUpInside)
        button.sizeToFit()
        button.borderWidth = 2
        button.borderColor = UIColor.blue
        
        return button
    }()
    
    lazy var versionLabel:UILabel = {
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let label = UILabel(frame: .zero)
        label.text = "App Version:  \(version) \nCopyright © 2020 Shotaro Maruyama.\nAll rights reserved."
        label.frame.size.height = 50
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 3
        label.sizeToFit()
        //        label.textColor = UIColor.black
        return label
    }()
    
    
    override func viewDidLoad() {
        view.addSubview(mailSendButton)
        view.addSubview(versionLabel)
//        view.addSubview(purchaseButton)
        
    }
    
    override func viewWillLayoutSubviews() {
        let viewSize = (width: self.view.bounds.width, height: self.view.bounds.height)
        
        self.versionLabel.center.y = viewSize.height * (3/6)
        self.versionLabel.frame.origin.x = self.view.bounds.minX + 10
        self.versionLabel.frame.size.width = viewSize.width
        
        self.mailSendButton.center = CGPoint(x: viewSize.width / 2, y: viewSize.height * (5/6))
        self.purchaseButton.center = CGPoint(x: viewSize.width / 2, y: viewSize.height * (1/6))
    }
    
    @objc func clickSendMailButton(sender: UIButton){
        dismiss(animated: true, completion: nil)
        infoMethodDelegate?.sendMail()
    }
    
    @objc func purchase(sender: UIButton){
        
        SwiftyStoreKit.purchaseProduct(PRODUCT_ID) { (result) in
            
            switch result{
            
            case .success(_):
                
                self.verifyPurchase()
                
                break
            case .error(let error):
                print(error)
                
                break
            }
            
            
        }
        
    }
    
    private func verifyPurchase(){
        
        //共有シークレット リストア
        let appeValidator = AppleReceiptValidator(service: .production, sharedSecret: "d5374a06f2c641a8a9133128155fe22c")
        SwiftyStoreKit.verifyReceipt(using: appeValidator) { (result) in
            
            switch result{
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifyPurchase(productId: self.PRODUCT_ID, inReceipt: receipt)
                switch purchaseResult{
                case.purchased:
                    self.setInValidAd()
                    break
                case .notPurchased:
                    //購入していない場合
                    self.setInValidAd()
                    break
                    
                }
            case .error(let error):
                print(error)
                break
            }
            
        }
    }
    
    @objc func restore(){
        //リストア機能
        SwiftyStoreKit.restorePurchases { (results) in
            if (results.restoreFailedPurchases.count > 0){
                self.setInValidAd()
                
            }else if(results.restoredPurchases.count > 0){
                self.setInValidAd()
            }
        }
    }
    
    func setInValidAd(){
        //広告非表示購入済みならtrue
        print("購入!orRestore!")
        let userDefaults = UserDefaults()
        userDefaults.setValue(true, forKey: "isPurchasedInValidAd")
    }
}
