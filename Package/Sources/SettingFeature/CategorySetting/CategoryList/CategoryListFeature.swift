//
//  CategoryListFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// カテゴリ設定画面
@Reducer
public struct CategoryListFeature: Sendable {
  public typealias Category = Domain.Category
  public init() {}

  /// CategoryUseCase
  @Dependency(\.categoryUseCase) var categoryUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// カテゴリ一覧
    var categoryList: [Category] = []
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
      /// カテゴリ編集タップ
      case editCategoryTapped(Category)
      /// スワイプで削除
      case swipeToDelete(Category)
    }

    public enum InternalAction: Equatable {
      /// すべてのカテゴリを取得した結果
      case fetchAllCategoryResponse([Category])
      /// カテゴリを追加
      case addCategory(Category)
      /// カテゴリを更新
      case updateCategory(Category)
      /// カテゴリを削除
      case deleteCategory(Category)
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
              let result = try await categoryUseCase.fetchAll()
              await send(.internal(.fetchAllCategoryResponse(result.items)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .addButtonTapped:
          state.destination = .addCategory(.init())
          return .none

        case .editCategoryTapped(let category):
          state.destination = .editCategory(.init(category: category))
          return .none

        case .swipeToDelete(let category):
          return .run(
            operation: { send in
              try await categoryUseCase.delete(category)
              await send(.internal(.deleteCategory(category)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchAllCategoryResponse(let result):
          state.categoryList = result
          return .none

        case .addCategory(let category):
          state.categoryList.append(category)
          return .none

        case .updateCategory(let category):
          if let index = state.categoryList.firstIndex(where: { $0.id == category.id }) {
            state.categoryList[index] = category
          }
          return .none

        case .deleteCategory(let category):
          if let index = state.categoryList.firstIndex(where: { $0.id == category.id }) {
            state.categoryList.remove(at: index)
          }
          return .none

        case .handleError(let errorInfo):
          // エラーハンドラーに送信
          errorHandler.send(errorInfo)
          return .none
        }

      case .destination(.presented(.addCategory(.delegate(.addCategory(let category))))):
        return .send(.internal(.addCategory(category)))

      case .destination(.presented(.editCategory(.delegate(.updateCategory(let category))))):
        return .send(.internal(.updateCategory(category)))

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension CategoryListFeature {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    // カテゴリ追加画面
    case addCategory(AddCategoryFeature)
    // カテゴリ編集画面
    case editCategory(EditCategoryFeature)
  }
}
