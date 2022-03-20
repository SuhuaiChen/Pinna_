//
//  UserSetting.swift
//  Pinna
///
//  Created by Matt Chen on 2022/3/20.
//

import Foundation


enum Key{
    static let low = "Low"
    static let medium = "Medium"
    static let high = "High"
    
}


struct UserSetting{
    
    static var shared = UserSetting()
    
    var low: Float{
        get {
            return UserDefaults.standard.float(forKey: Key.low)
        }
        set(newVal){
            UserDefaults.standard.set(newVal, forKey: Key.low)
        }
    }
   

    
    var medium: Float{
        get {
            return UserDefaults.standard.float(forKey: Key.medium)
        }
        set(newVal){
            UserDefaults.standard.set(newVal, forKey: Key.medium)
        }
    }
    
    var high: Float{
        get {
            return UserDefaults.standard.float(forKey: Key.high)
        }
        set(newVal){
            UserDefaults.standard.set(newVal, forKey: Key.high)
        }
    }
    

    
    func registerDefaults(){
        let factorySettings: [String: Any] = [Key.low: 0.5,
                                              Key.medium: 0.5,
                                              Key.high: 0.5]
        UserDefaults.standard.register(defaults: factorySettings)
    }
    
    
}

