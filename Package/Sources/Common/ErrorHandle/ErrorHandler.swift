//
//  ErrorHandler.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/19.
//

import ComposableArchitecture
import Foundation

/// ErrorHandler
@DependencyClient
public struct ErrorHandler: Sendable {
  /// エラー情報を送信
  public var send: @Sendable (_ errorInfo: ErrorInfo) -> Void
  /// エラー情報のストリーム
  public var stream: @Sendable () -> AsyncStream<ErrorInfo> = { AsyncStream { _ in } }
}

extension ErrorHandler: DependencyKey {
  /// ErrorHandlerのDependencyKey
  public static let liveValue: ErrorHandler = {
    let (stream, continuation) = AsyncStream<ErrorInfo>.makeStream()

    return Self(
      send: { continuation.yield($0) },
      stream: { stream }
    )
  }()
}

extension ErrorHandler: TestDependencyKey {
  public static let testValue: ErrorHandler = Self()
  public static let previewValue: ErrorHandler = Self()
}

extension DependencyValues {
  /// ErrorHandlerのDependencyValues
  public var errorHandler: ErrorHandler {
    get { self[ErrorHandler.self] }
    set { self[ErrorHandler.self] = newValue }
  }
}
