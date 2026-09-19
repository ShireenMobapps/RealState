//
//  AppDelegate.swift
//  AIPoweredRealEstate
//
//  Created by Shireen on 18/08/26.
//

import UIKit
import GoogleMaps

@main

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIScrollView.appearance().bounces = false
        UIScrollView.appearance().alwaysBounceVertical = false
        UIScrollView.appearance().alwaysBounceHorizontal = false
        GMSServices.provideAPIKey(Constant.googleMapsAPIKey)
        LanguageManager.enableRuntimeLocalization()
        CommonMethods.installKeyboardDoneButton()
        CommonMethods.installBackChevronOnly()
        UINavigationBar.appearance().tintColor = .darkThemeColor
        UITabBar.appearance().tintColor = .darkThemeColor
        NotificationCenter.default.addObserver(self, selector: #selector(updateSemantic), name: LanguageManager.didChange, object: nil)
        
        //craete array here
        var arr:[Int] = [1,2,3,4]
        print(arr)
        var arr2:[Int] = [1,2,3,4]
        print(arr2)
        
      
        
        return true
    }
    
    @objc func updateSemantic(){
        UIView.appearance().semanticContentAttribute = .forceLeftToRight
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

