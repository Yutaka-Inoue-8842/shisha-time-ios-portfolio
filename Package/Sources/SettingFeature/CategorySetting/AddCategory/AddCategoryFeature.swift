//
//  AddCategoryFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// カテゴリ追加画面
@Reducer
public struct AddCategoryFeature: Sendable {
  public typealias Category = Domain.Category
  public init() {}

  /// CategoryUseCase
  @Dependency(\.categoryUseCase) var categoryUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler
  /// dismiss
  @Dependency(\.dismiss) var dismiss

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// カテゴリ名
    var categoryName: String = ""
  }

  public enum Action: ViewAction, BindableAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// 子画面への委譲アクション
    case delegate(Delegate)
    /// Binding
    case binding(BindingAction<State>)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// 保存ボタンタップ
      case saveButtonTapped
    }

    public enum InternalAction: Equatable {
      /// カテゴリ保存レスポンス
      case saveCategoryResponse(Category)
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// カテゴリ追加
      case addCategory(Category)
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
          let trimmedName = state.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)

          return .run(
            operation: { [categoryName = trimmedName] send in
              let category = Category(
                name: categoryName,
                createdAt: .init(Date()),
                updatedAt: .init(Date())
              )
              let result = try await categoryUseCase.create(category)
              await send(.internal(.saveCategoryResponse(result)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
        }

      case .internal(let internalAction):
        switch internalAction {
        case .saveCategoryResponse(let category):
          return .concatenate(
            .send(.delegate(.addCategory(category))),
            .run { _ in
              await dismiss()
            }
          )

        case .handleError(let errorInfo):
          // エラーハンドラーに送信
          errorHandler.send(errorInfo)
          return .none
        }

      case .delegate:
        return .none

      case .binding:
        return .none
      }
    }
  }
}
