//
//  TableValidationError.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/20.
//

import Foundation

/// テーブルバリデーションエラー
public enum TableValidationError: LocalizedError {
  /// テーブル名が空
  case invalidNameEmpty
  /// テーブル名が長すぎる
  case invalidNameLength

  public var errorDescription: String? {
    switch self {
    case .invalidNameEmpty:
      return "テーブル名が入力されていません。"
    case .invalidNameLength:
      return "テーブル名が長すぎます。"
    }
  }

  public var failureReason: String? {
    switch self {
    case .invalidNameEmpty:
      return "テーブルを作成するにはテーブル名の入力が必要です。"
    case .invalidNameLength:
      return "テーブル名は20文字以内で入力してください。"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidNameEmpty:
      return "テーブル名を入力してください。"
    case .invalidNameLength:
      return "テーブル名を20文字以内で入力し直してください。"
    }
  }
}
