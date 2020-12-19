//
//  EditorViewModel.swift
//  InstantNote
//
//  Created by akio0911 on 2020/12/19.
//

import Foundation

final class EditorViewModel {
    var oldText:String = ""
    
    let textViewUndoManager = UndoManager()
    
    var isPurchasedInValidAd: Bool {
        get{
            return userDefaults.bool(forKey: "isPurchasedInValidAd")
        }
    }
    
    let userDefaults = UserDefaults()
    
    var isReceivedAd = false
}
