import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // 应用启动配置
        setupAppearance()
        return true
    }
    
    private func setupAppearance() {
        // 配置全局外观
        let primaryTextColor = UIColor(red: 0.17, green: 0.24, blue: 0.31, alpha: 1.0)
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: primaryTextColor
        ]
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: primaryTextColor
        ]
    }
}
