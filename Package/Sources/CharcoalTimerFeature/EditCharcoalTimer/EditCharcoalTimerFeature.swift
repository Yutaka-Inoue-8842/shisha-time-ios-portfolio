//
//  EditCharcoalTimerFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// タイマー編集画面
@Reducer
public struct EditCharcoalTimerFeature: Sendable {
  public typealias Timer = Domain.Timer
  public init() {}

  /// TimerUseCase
  @Dependency(\.timerUseCase) var timerUseCase
  /// TableUseCase
  @Dependency(\.tableUseCase) var tableUseCase
  /// TimeIntervalUseCase
  @Dependency(\.timeIntervalUseCase) var timeIntervalUseCase
  /// dismiss
  @Dependency(\.dismiss) var dismiss
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    public init(timer: Timer) {
      self.timer = timer
      self.selectedTable = nil
      self.selectedMinutesInterval = timer.minutesInterval
    }
    /// 編集対象のタイマー
    var timer: Timer
    /// 卓の選択肢
    var tables: [Table] = []
    /// 選択中の卓
    var selectedTable: Table?
    /// タイマー時間の選択肢
    var minutesIntervals: [Int] = []
    /// 選択中のタイマー時間
    var selectedMinutesInterval: Int?
  }

  public enum Action: ViewAction, BindableAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// bindingアクション
    case binding(BindingAction<State>)
    /// DelegateAction
    case delegate(Delegate)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// Saveをタップ
      case saveButtonTapped
    }

    public enum InternalAction: Equatable {
      /// 卓の一覧取得完了時のレスポンス
      case fetchAllTableResponse([Table])
      /// 現在のタイマーのテーブル設定
      case setCurrentTable(Table?)
      /// タイマーを保存
      case save
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// タイマー更新
      case updateTimer(Timer)
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

        case .saveButtonTapped:
          return .send(.internal(.save))
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchAllTableResponse(let result):
          state.tables = result
          // 現在のタイマーに紐づくテーブルを取得
          return .run(
            operation: { [timer = state.timer] send in
              do {
                let currentTable = try await timer.table
                await send(.internal(.setCurrentTable(currentTable)))
              } catch {
                await send(.internal(.setCurrentTable(nil)))
              }
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .setCurrentTable(let table):
          state.selectedTable = table
          return .none

        case .save:
          return .run(
            operation: { [state] send in
              let result = try await timerUseCase.update(
                timer: state.timer,
                newMinutesInterval: state.selectedMinutesInterval,
                newTable: state.selectedTable
              )
              await send(.delegate(.updateTimer(result)))
              await dismiss()
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

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
