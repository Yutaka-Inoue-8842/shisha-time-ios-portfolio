//
//  TableListFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// テーブル設定画面
@Reducer
public struct TableListFeature: Sendable {
  public init() {}

  /// TableUseCase
  @Dependency(\.tableUseCase) var tableUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// テーブル一覧
    var tableList: [Table] = []
    /// 画面遷移のState
    @Presents var destination: Destination.State?
  }

  public enum Action: ViewAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// 子画面のアクション
    case destination(PresentationAction<Destination.Action>)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// 追加ボタンタップ
      case addButtonTapped
      /// テーブル編集タップ
      case editTableTapped(Table)
    }

    public enum InternalAction: Equatable {
      /// すべてのテーブルを取得した結果
      case fetchAllTableResponse([Table])
      /// ステートの配列にテーブルを追加
      case addTable(Table)
      /// ステートの配列のテーブルを更新
      case updateTable(Table)
      /// ステートの配列からテーブルを削除
      case removeTable(Table)
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
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

        case .addButtonTapped:
          state.destination = .addTable(.init())
          return .none

        case .editTableTapped(let table):
          state.destination = .editTable(.init(table: table))
          return .none
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchAllTableResponse(let result):
          state.tableList = result
          return .none

        case .addTable(let table):
          // 一番上にテーブル追加
          state.tableList.insert(table, at: 0)
          return .none

        case .updateTable(let table):
          // テーブルを更新
          if let index = state.tableList.firstIndex(where: { $0.id == table.id }) {
            state.tableList[index] = table
          }
          return .none

        case .removeTable(let table):
          // テーブルを削除
          state.tableList.removeAll { $0.id == table.id }
          return .none

        case .handleError(let errorInfo):
          errorHandler.send(errorInfo)
          return .none
        }

      case .destination(.presented(.addTable(.delegate(.addTable(let table))))):
        return .send(.internal(.addTable(table)))

      case .destination(.presented(.editTable(.delegate(.updateTable(let table))))):
        return .send(.internal(.updateTable(table)))

      case .destination(.presented(.editTable(.delegate(.deleteTable(let table))))):
        return .send(.internal(.removeTable(table)))

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension TableListFeature {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    // テーブル追加画面
    case addTable(AddTableFeature)
    // テーブル編集画面
    case editTable(EditTableFeature)
  }
}
