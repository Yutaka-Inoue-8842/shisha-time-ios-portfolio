//
//  EditCategoryFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// カテゴリ編集画面
@Reducer
public struct EditCategoryFeature: Sendable {
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
    public init(category: Category) {
      self.category = category
      self.categoryName = category.name
    }
    /// 編集対象のカテゴリ
    let category: Category
    /// カテゴリ名
    var categoryName: String
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
      /// カテゴリ更新レスポンス
      case updateCategoryResponse(Category)
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// カテゴリ更新
      case updateCategory(Category)
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
            operation: { [category = state.category, categoryName = trimmedName] send in
              var updatedCategory = category
              updatedCategory.name = categoryName
              updatedCategory.updatedAt = .init(Date())

              let result = try await categoryUseCase.update(updatedCategory)
              await send(.internal(.updateCategoryResponse(result)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
        }

      case .internal(let internalAction):
        switch internalAction {
        case .updateCategoryResponse(let category):
          return .concatenate(
            .send(.delegate(.updateCategory(category))),
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
