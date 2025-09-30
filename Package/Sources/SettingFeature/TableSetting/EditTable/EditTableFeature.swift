//
//  EditTableFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/25.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// テーブル編集画面
@Reducer
public struct EditTableFeature: Sendable {
  public init() {}

  /// TableUseCase
  @Dependency(\.tableUseCase) var tableUseCase
  /// dismiss
  @Dependency(\.dismiss) var dismiss
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    public init(table: Table) {
      self.table = table
      self.tableName = table.name
    }
    /// 編集対象のテーブル
    var table: Table
    /// テーブル名
    var tableName: String = ""
    /// アラートのState
    @Presents var alert: AlertState<Action.AlertAction>?
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
    /// alertのアクション
    case alert(PresentationAction<AlertAction>)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// Saveをタップ
      case saveButtonTapped
      /// Backをタップ
      case backButtonTapped
      /// 削除ボタンをタップ
      case deleteButtonTapped
    }

    public enum InternalAction: Equatable {
      /// テーブルを保存
      case save
      /// テーブルを削除
      case delete
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// テーブル更新
      case updateTable(Table)
      /// テーブル削除
      case deleteTable(Table)
    }

    public enum AlertAction: Equatable {
      /// 削除確認
      case confirmDelete
      /// キャンセル
      case cancel
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

        case .saveButtonTapped:
          return .send(.internal(.save))

        case .backButtonTapped:
          return .run { _ in
            await dismiss()
          }

        case .deleteButtonTapped:
          state.alert = AlertState {
            TextState("テーブルを削除しますか？")
          } actions: {
            ButtonState(role: .destructive, action: .send(.confirmDelete)) {
              TextState("削除")
            }
            ButtonState(role: .cancel, action: .send(.cancel)) {
              TextState("キャンセル")
            }
          } message: {
            TextState("この操作は取り消せません。")
          }
          return .none
        }

      case .internal(let internalAction):
        switch internalAction {
        case .save:
          return .run(
            operation: { [state] send in
              if state.table.name != state.tableName {
                let result = try await tableUseCase.update(
                  table: state.table,
                  newName: state.tableName
                )
                await send(.delegate(.updateTable(result)))
              }
              await dismiss()
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .delete:
          return .run(
            operation: { [state] send in
              try await tableUseCase.delete(state.table)
              await send(.delegate(.deleteTable(state.table)))
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

      case .alert(.presented(let alertAction)):
        switch alertAction {
        case .confirmDelete:
          return .send(.internal(.delete))
        case .cancel:
          return .none
        }

      case .alert(.dismiss):
        return .none
      }
    }
    .ifLet(\.$alert, action: \.alert)
  }
}
