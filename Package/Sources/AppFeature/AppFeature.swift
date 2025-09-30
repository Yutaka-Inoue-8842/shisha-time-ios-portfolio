//
//  AppFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/10.
//

import AppTabFeature
import Common
import ComposableArchitecture
import Foundation

@Reducer
public struct AppFeature: Sendable {
  public init() {}

  /// ErrorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// AppTabFeatureのState
    var appTab: AppTabFeature.State = .init()
    /// アラートのState
    @Presents var alert: AlertState<Action.AlertAction>?
  }

  public enum Action: ViewAction, Equatable, @unchecked Sendable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// AppTabFeatureのアクション
    case appTab(AppTabFeature.Action)
    /// alertのアクション
    case alert(PresentationAction<AlertAction>)

    public enum ViewAction: Equatable {
      /// 初期処理
      case onAppear
    }

    public enum InternalAction: Equatable {
      /// 監視処理開始
      case startObservation
      /// 監視処理停止
      case stopObservation
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum AlertAction: Equatable {
      /// アラートを閉じる
      case dismiss
    }
  }

  // タスクキャンセル用のID
  enum CancelID {
    // 監視アクション
    case observer
  }

  public var body: some ReducerOf<Self> {

    Scope(state: \.appTab, action: \.appTab) {
      AppTabFeature()
    }

    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          return .send(.internal(.startObservation))
        }

      case .internal(let internalAction):
        switch internalAction {
        case .startObservation:
          return .run { send in
            for await errorInfo in errorHandler.stream() {
              await send(.internal(.handleError(errorInfo)))
            }
          }
          .cancellable(id: CancelID.observer, cancelInFlight: true)

        case .stopObservation:
          return .cancel(id: CancelID.observer)

        case .handleError(let errorInfo):
          state.alert = AlertState {
            TextState(errorInfo.title)
          } actions: {
            ButtonState(role: .cancel, action: .send(.dismiss)) {
              TextState(errorInfo.buttonText)
            }
          } message: {
            TextState(errorInfo.message)
          }
        }
        return .none

      case .appTab:
        return .none

      case .alert:
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}
