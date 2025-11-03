//
//  RepositoryEnvironment.swift
//  Package
//
//  Created by Claude Code on 2025/10/14.
//

import ComposableArchitecture
import Foundation

/// Repositoryの実行環境を定義
public enum RepositoryEnvironment: Sendable {
  /// 本番環境（Amplify使用）
  case production
  /// デモ環境（オンメモリ使用）
  case demo

  /// 環境名（デバッグ用）
  public var name: String {
    switch self {
    case .production:
      return "本番環境"
    case .demo:
      return "デモ環境"
    }
  }
}

// MARK: - TCA Dependency

extension DependencyValues {
  /// Repository環境の取得/設定
  public var repositoryEnvironment: RepositoryEnvironment {
    get { self[RepositoryEnvironmentKey.self] }
    set { self[RepositoryEnvironmentKey.self] = newValue }
  }
}

/// Repository環境のDependencyKey
private enum RepositoryEnvironmentKey: DependencyKey {
  /// Live値：ビルド設定に基づいて自動決定（並行性安全）
  static let liveValue: RepositoryEnvironment = {
    #if DEMO
      return .demo
    #elseif DEBUG
      return .production
    #else
      return .production
    #endif
  }()

  /// Test値：テスト時は常にデモ環境
  static let testValue: RepositoryEnvironment = .demo

  /// Preview値：プレビュー時はデモ環境
  static let previewValue: RepositoryEnvironment = .demo
}
