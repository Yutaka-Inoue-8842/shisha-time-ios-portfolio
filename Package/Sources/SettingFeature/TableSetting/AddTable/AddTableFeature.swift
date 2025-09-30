//
//  AddTableFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/04/12.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// テーブル追加画面
@Reducer
public struct AddTableFeature: Sendable {
  public init() {}

  /// tableUseCase
  @Dependency(\.tableUseCase) var tableUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler
  /// Dismiss
  @Dependency(\.dismiss) var dismiss

  @ObservableState
  public struct State: Equatable, Sendable {
    public init() {}
    /// テーブル名
    var tableName: String = ""
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
      ///　Tableの新規作成
      case addTable
    }

    public enum InternalAction: Equatable {
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// タイマー追加
      case addTable(Table)
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          return .none

        case .addTable:
          return .run(
            operation: { [state] send in
              let result = try await tableUseCase.create(
                name: state.tableName
              )
              await send(.delegate(.addTable(result)))
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
