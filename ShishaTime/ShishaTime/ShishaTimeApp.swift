//
//  ShishaTimeApp.swift
//  ShishaTime
//
//  Created by Yutaka Inoue on 2024/10/03.
//

import AWSAPIPlugin
import Amplify
import AppFeature
import ComposableArchitecture
import Domain
import SwiftUI
import UIKit
import UserNotifications

@main
struct ShishaTimeApp: App {
  init() {
    // 実行環境を判定
    let environment = determineEnvironment()

    // デモ環境以外でAmplifyを初期化
    if environment == .production {
      do {
        try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: AmplifyModels()))
        try Amplify.configure(with: .amplifyOutputs)
      } catch {}
    }
  }

  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      AppView(
        store: withDependencies {
          // アプリルート側でRepository環境を差し替え
          $0.repositoryEnvironment = determineEnvironment()
        } operation: {
          Store(initialState: .init()) {
            AppFeature()
          }
        }
      )
    }
  }

  /// 実行環境を判定
  /// - Returns: 判定された環境
  ///
  /// この関数で環境を判定し、withDependenciesで設定することで、
  /// アプリ全体で使用するRepositoryを切り替えることができます。
  ///
  /// 環境切り替えのポイント：
  /// - DEMO: デモ環境（オンメモリRepository）※外部の方の動作確認用
  /// - DEBUG: 開発環境（本番Repository）※Amplifyの認証を通さないと動作しない
  /// - Release: 本番環境（本番Repository）※Amplifyの認証を通さないと動作しない
  private func determineEnvironment() -> RepositoryEnvironment {
    #if DEMO
      return .demo
    #elseif DEBUG
      // Debug環境でもデモRepositoryを使いたい場合は .demo に変更
      return .production
    #else
      return .production
    #endif
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
