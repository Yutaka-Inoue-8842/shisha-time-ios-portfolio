//
//  CategoryValidationError.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Foundation

public enum CategoryValidationError: LocalizedError {
  case invalidNameEmpty
  case invalidNameLength

  public var errorDescription: String? {
    switch self {
    case .invalidNameEmpty:
      return "カテゴリ名が入力されていません。"
    case .invalidNameLength:
      return "カテゴリ名が長すぎます。"
    }
  }

  public var failureReason: String? {
    switch self {
    case .invalidNameEmpty:
      return "カテゴリを作成するにはカテゴリ名の入力が必要です。"
    case .invalidNameLength:
      return "カテゴリ名は20文字以内で入力してください。"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidNameEmpty:
      return "カテゴリ名を入力してください。"
    case .invalidNameLength:
      return "カテゴリ名を20文字以内で入力し直してください。"
    }
  }
}
