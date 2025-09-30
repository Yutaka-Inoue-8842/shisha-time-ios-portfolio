//
//  TemplateValidationError.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/20.
//

import Foundation

/// テンプレートバリデーションエラー
public enum TemplateValidationError: LocalizedError {
  /// コンテンツが無効
  case invalidContent
  /// タイトルが空
  case invalidTitleEmpty
  /// タイトルが長すぎる
  case invalidTitleLength

  public var errorDescription: String? {
    switch self {
    case .invalidContent:
      return "テンプレートのコンテンツが無効です。"
    case .invalidTitleEmpty:
      return "テンプレートタイトルが入力されていません。"
    case .invalidTitleLength:
      return "テンプレートタイトルが長すぎます。"
    }
  }

  public var failureReason: String? {
    switch self {
    case .invalidContent:
      return "テンプレートのコンテンツが正しく変換できませんでした。"
    case .invalidTitleEmpty:
      return "テンプレートを作成するにはタイトルの入力が必要です。"
    case .invalidTitleLength:
      return "テンプレートタイトルは50文字以内で入力してください。"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidContent:
      return "テンプレートの内容を確認し、再度お試しください。"
    case .invalidTitleEmpty:
      return "テンプレートタイトルを入力してください。"
    case .invalidTitleLength:
      return "テンプレートタイトルを50文字以内で入力し直してください。"
    }
  }
}
