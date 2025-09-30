//
//  AddCharcoalTimer.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/11/26.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct AddCharcoalTimerFeature: Sendable {
  public init() {}

  /// timerUseCase
  @Dependency(\.timerUseCase) var timerUseCase
  /// tableUseCase
  @Dependency(\.tableUseCase) var tableUseCase
  /// tableUseCase
  @Dependency(\.timeIntervalUseCase) var timeIntervalUseCase
  /// Dismiss
  @Dependency(\.dismiss) var dismiss
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable, Sendable {
    public init() {}
    /// 卓の選択肢
    var tables: [Table] = []
    /// タイマー時間の選択肢
    var minutesIntervals: [Int] = []
    /// 選択中の卓番号
    var selectedTable: Table?
    /// 選択中のタイマー時間
    var selectedMinutesInterval: Int?
  }

  public enum Action: BindableAction, ViewAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// BindingAction
    case binding(BindingAction<State>)
    /// DelegateAction
    case delegate(Delegate)

    public enum ViewAction: Equatable {
      /// 初期処理
      case onAppear
      ///　CharcoalTimerの新規作成
      case addCharcoalTimer
    }

    public enum InternalAction: Equatable {
      /// 卓の一覧取得完了時のレスポンス
      case fetchAllTableResponse([Table])
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// タイマー追加
      case addTimer(Domain.Timer)
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          state.minutesIntervals = timeIntervalUseCase.fetch().compactMap { Int($0.timeInterval) }
          return .run(
            operation: { send in
              let result = try await tableUseCase.fetchAll()
              await send(.internal(.fetchAllTableResponse(result)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .addCharcoalTimer:
          return .run(
            operation: { [state] send in
              let result = try await timerUseCase.create(
                minutesInterval: state.selectedMinutesInterval,
                table: state.selectedTable
              )
              await send(.delegate(.addTimer(result)))
              await dismiss()
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchAllTableResponse(let result):
          state.tables = result
          return .none

        case .handleError(let errorInfo):
          errorHandler.send(errorInfo)
          return .none
        }

      case .binding:
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
