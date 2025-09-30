//
//  DocumentValidationError.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/20.
//

import Foundation

/// ドキュメントバリデーションエラー
public enum DocumentValidationError: LocalizedError {
  /// コンテンツが無効
  case invalidContent
  /// コンテンツが空
  case invalidContentEmpty
  /// コンテンツが長すぎる
  case invalidContentLength

  public var errorDescription: String? {
    switch self {
    case .invalidContent:
      return "ドキュメントのコンテンツが無効です。"
    case .invalidContentEmpty:
      return "ドキュメントの内容が入力されていません。"
    case .invalidContentLength:
      return "ドキュメントの内容が長すぎます。"
    }
  }

  public var failureReason: String? {
    switch self {
    case .invalidContent:
      return "ドキュメントのコンテンツが正しく変換できませんでした。"
    case .invalidContentEmpty:
      return "ドキュメントを作成するには内容の入力が必要です。"
    case .invalidContentLength:
      return "ドキュメントの内容は10000文字以内で入力してください。"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidContent:
      return "ドキュメントの内容を確認し、再度お試しください。"
    case .invalidContentEmpty:
      return "ドキュメントの内容を入力してください。"
    case .invalidContentLength:
      return "ドキュメントの内容を短くして、再度お試しください。"
    }
  }
}
