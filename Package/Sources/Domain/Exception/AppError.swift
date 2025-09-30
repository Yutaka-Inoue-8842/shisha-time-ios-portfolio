//
//  AppError.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/06/08.
//

import Foundation

public enum AppError: LocalizedError {
  case unknown

  public var errorDescription: String? {
    switch self {
    case .unknown:
      return "予期しないエラーが発生しました。"
    }
  }

  public var failureReason: String? {
    switch self {
    case .unknown:
      return "アプリケーション内で予期しない問題が発生しました。"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .unknown:
      return "アプリを再起動するか、しばらく時間をおいてから再度お試しください。"
    }
  }
}
