//
//  TimerValidationError.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/04/27.
//

import Foundation

public enum TimerValidationError: LocalizedError {
  case invalidTableSelection
  case invalidMinutesIntervalSelection
  case invalidTableNameLength

  public var errorDescription: String? {
    switch self {
    case .invalidTableSelection:
      return "テーブルが選択されていません。"
    case .invalidMinutesIntervalSelection:
      return "タイムインターバルが選択されていません。"
    case .invalidTableNameLength:
      return "テーブル名が長すぎます。"
    }
  }

  public var failureReason: String? {
    switch self {
    case .invalidTableSelection:
      return "タイマーを作成するにはテーブルの選択が必要です。"
    case .invalidMinutesIntervalSelection:
      return "タイマーを作成するにはタイムインターバルの選択が必要です。"
    case .invalidTableNameLength:
      return "テーブル名は20文字以内で入力してください。"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidTableSelection:
      return "利用可能なテーブルから一つを選択してください。"
    case .invalidMinutesIntervalSelection:
      return "利用可能なタイムインターバルから一つを選択してください。"
    case .invalidTableNameLength:
      return "テーブル名を20文字以内で入力し直してください。"
    }
  }
}
