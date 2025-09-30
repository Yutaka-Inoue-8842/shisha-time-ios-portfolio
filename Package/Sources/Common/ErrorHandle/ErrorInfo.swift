//
//  ErrorInfo.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/19.
//

import Foundation

public struct ErrorInfo: Equatable, Sendable {
  public let title: String
  public let message: String
  public let buttonText: String

  public init(
    title: String,
    message: String,
    buttonText: String = "OK"
  ) {
    self.title = title
    self.message = message
    self.buttonText = buttonText
  }
}

extension Error {
  public func toErrorInfo(buttonText: String = "OK") -> ErrorInfo {
    let message =
      self.localizedDescription.isEmpty
      ? String(describing: self)
      : self.localizedDescription

    return ErrorInfo(
      title: "エラーが発生しました",
      message: message,
      buttonText: buttonText
    )
  }
}
