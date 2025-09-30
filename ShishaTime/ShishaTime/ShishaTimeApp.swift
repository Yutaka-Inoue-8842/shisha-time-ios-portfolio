//
//  ShishaTimeApp.swift
//  ShishaTime
//
//  Created by Yutaka Inoue on 2024/10/03.
//

import AWSAPIPlugin
import Amplify
import AppFeature
import Domain
import SwiftUI
import UIKit
import UserNotifications

@main
struct ShishaTimeApp: App {
  init() {
    do {
      try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
      try Amplify.configure(with: .amplifyOutputs)
    } catch {
      print("Unable to configure Amplify \(error)")
    }
  }

  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      AppView(
        store: .init(
          initialState: .init()
        ) {
          AppFeature()
        }
      )
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // 通知のデリゲートを設定
    UNUserNotificationCenter.current().delegate = self
    return true
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // フォアグラウンドで通知を表示する
    completionHandler([.banner, .sound])
  }
}
