//
//  AppFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/31.
//

import AppTabFeature
import Common
import ComposableArchitecture
import Domain
import Foundation
import Testing

@testable import AppFeature

@MainActor
struct AppFeatureTests {
  typealias Feature = AppFeature

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_startsObservation() async {
    let mockErrorInfo = ErrorInfo(
      title: "テストエラー",
      message: "テスト用のエラーメッセージ",
      buttonText: "OK"
    )

    let errorStreamSubject = AsyncStream<ErrorInfo>.makeStream()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { errorStreamSubject.stream }
      )
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.startObservation))

    // エラーハンドラーのストリームにエラーを送信
    errorStreamSubject.continuation.yield(mockErrorInfo)
    await store.receive(.internal(.handleError(mockErrorInfo))) {
      $0.alert = AlertState {
        TextState(mockErrorInfo.title)
      } actions: {
        ButtonState(role: .cancel, action: .send(.dismiss)) {
          TextState(mockErrorInfo.buttonText)
        }
      } message: {
        TextState(mockErrorInfo.message)
      }
    }

    // ストリームを終了
    await store.send(.internal(.stopObservation))

    await store.finish()
  }

  // MARK: - Internalアクション

  @Test @MainActor
  func testStartObservation_handlesErrorFromStream() async {
    let mockErrorInfo = ErrorInfo(
      title: "ネットワークエラー",
      message: "接続に失敗しました",
      buttonText: "閉じる"
    )

    let errorStreamSubject = AsyncStream<ErrorInfo>.makeStream()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { errorStreamSubject.stream }
      )
    }

    await store.send(.internal(.startObservation))

    // エラーハンドラーのストリームにエラーを送信
    errorStreamSubject.continuation.yield(mockErrorInfo)
    await store.receive(.internal(.handleError(mockErrorInfo))) {
      $0.alert = AlertState {
        TextState(mockErrorInfo.title)
      } actions: {
        ButtonState(role: .cancel, action: .send(.dismiss)) {
          TextState(mockErrorInfo.buttonText)
        }
      } message: {
        TextState(mockErrorInfo.message)
      }
    }

    // ストリームを終了
    await store.send(.internal(.stopObservation))

    await store.finish()
  }

  @Test @MainActor
  func testHandleError_setsAlert() async {
    let mockErrorInfo = ErrorInfo(
      title: "バリデーションエラー",
      message: "必須項目が入力されていません",
      buttonText: "了解"
    )

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.handleError(mockErrorInfo))) {
      $0.alert = AlertState {
        TextState(mockErrorInfo.title)
      } actions: {
        ButtonState(role: .cancel, action: .send(.dismiss)) {
          TextState(mockErrorInfo.buttonText)
        }
      } message: {
        TextState(mockErrorInfo.message)
      }
    }

    await store.finish()
  }

  // MARK: - AppTabアクション

  @Test @MainActor
  func testAppTabAction_passesThrough() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        return .init(items: [], nextToken: nil)
      }
    }

    // AppTabアクションはそのまま通される
    await store.send(.appTab(.view(.onAppear)))
    await store.finish()
  }

  // MARK: - Alertアクション

  @Test @MainActor
  func testAlertDismiss_dismissesAlert() async {
    var initialState = Feature.State()
    initialState.alert = AlertState {
      TextState("テスト")
    } actions: {
      ButtonState(role: .cancel, action: .send(.dismiss)) {
        TextState("OK")
      }
    }

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.alert(.presented(.dismiss))) {
      $0.alert = nil
    }
    await store.finish()
  }

  @Test @MainActor
  func testAlertDismissAction_clearsAlert() async {
    var initialState = Feature.State()
    initialState.alert = AlertState {
      TextState("エラー")
    } actions: {
      ButtonState(role: .cancel, action: .send(.dismiss)) {
        TextState("閉じる")
      }
    }

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.alert(.dismiss)) {
      $0.alert = nil
    }
    await store.finish()
  }

  // MARK: - 統合テスト

  @Test @MainActor
  func testIntegration_errorObservationWorkflow() async {
    let mockErrorInfo1 = ErrorInfo(
      title: "エラー1",
      message: "最初のエラー",
      buttonText: "OK"
    )
    let mockErrorInfo2 = ErrorInfo(
      title: "エラー2",
      message: "二番目のエラー",
      buttonText: "閉じる"
    )

    let errorStreamSubject = AsyncStream<ErrorInfo>.makeStream()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { errorStreamSubject.stream }
      )
    }

    // 初期表示でObservation開始
    await store.send(.view(.onAppear))
    await store.receive(.internal(.startObservation))

    // 最初のエラーを受信
    errorStreamSubject.continuation.yield(mockErrorInfo1)
    await store.receive(.internal(.handleError(mockErrorInfo1))) {
      $0.alert = AlertState {
        TextState(mockErrorInfo1.title)
      } actions: {
        ButtonState(role: .cancel, action: .send(.dismiss)) {
          TextState(mockErrorInfo1.buttonText)
        }
      } message: {
        TextState(mockErrorInfo1.message)
      }
    }

    // アラートを閉じる
    await store.send(.alert(.presented(.dismiss))) {
      $0.alert = nil
    }

    // 二番目のエラーを受信
    errorStreamSubject.continuation.yield(mockErrorInfo2)
    await store.receive(.internal(.handleError(mockErrorInfo2))) {
      $0.alert = AlertState {
        TextState(mockErrorInfo2.title)
      } actions: {
        ButtonState(role: .cancel, action: .send(.dismiss)) {
          TextState(mockErrorInfo2.buttonText)
        }
      } message: {
        TextState(mockErrorInfo2.message)
      }
    }

    // ストリームを終了
    await store.send(.internal(.stopObservation))

    await store.finish()
  }

  @Test @MainActor
  func testIntegration_appTabInteraction() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        return .init(items: [], nextToken: nil)
      }
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { AsyncStream { _ in } }
      )
    }

    // アプリ全体の初期処理
    await store.send(.view(.onAppear))
    await store.receive(.internal(.startObservation))

    // AppTabアクションの動作確認
    await store.send(.appTab(.view(.hamburgerMenuTapped))) {
      $0.appTab.sidebar.isPresented.toggle()
    }

    // ストリームを終了
    await store.send(.internal(.stopObservation))

    await store.finish()
  }

  // MARK: - 状態の境界値テスト

  @Test @MainActor
  func testInitialState() async {
    let state = Feature.State()

    // 初期状態の検証
    #expect(state.alert == nil)

    let store = TestStore(initialState: state) {
      Feature()
    }

    await store.finish()
  }

  @Test @MainActor
  func testMultipleErrorHandling() async {
    let errors = [
      ErrorInfo(title: "エラー1", message: "メッセージ1", buttonText: "OK"),
      ErrorInfo(title: "エラー2", message: "メッセージ2", buttonText: "閉じる"),
      ErrorInfo(title: "エラー3", message: "メッセージ3", buttonText: "了解")
    ]

    let errorStreamSubject = AsyncStream<ErrorInfo>.makeStream()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { errorStreamSubject.stream }
      )
    }

    await store.send(.internal(.startObservation))

    // 複数のエラーを連続で処理
    for error in errors {
      errorStreamSubject.continuation.yield(error)
      await store.receive(.internal(.handleError(error))) {
        $0.alert = AlertState {
          TextState(error.title)
        } actions: {
          ButtonState(role: .cancel, action: .send(.dismiss)) {
            TextState(error.buttonText)
          }
        } message: {
          TextState(error.message)
        }
      }

      // アラートを閉じる
      await store.send(.alert(.presented(.dismiss))) {
        $0.alert = nil
      }
    }

    // ストリームを終了
    await store.send(.internal(.stopObservation))

    await store.finish()
  }

  // MARK: - Scope機能のテスト

  @Test @MainActor
  func testAppTabScopeIntegration() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        return .init(items: [], nextToken: nil)
      }
    }

    // AppTabFeatureのアクションが適切にスコープされることを確認
    await store.send(.appTab(.view(.onAppear)))

    await store.finish()
  }

  // MARK: - エラーハンドリングのテスト

  @Test @MainActor
  func testErrorHandlerStreamCancellation() async {
    let errorStreamSubject = AsyncStream<ErrorInfo>.makeStream()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { errorStreamSubject.stream }
      )
    }

    await store.send(.internal(.startObservation))

    // ストリームを終了
    errorStreamSubject.continuation.finish()

    await store.finish()
  }

}
