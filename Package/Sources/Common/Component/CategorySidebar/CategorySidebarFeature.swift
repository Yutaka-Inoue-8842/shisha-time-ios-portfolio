//
//  SidebarFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct CategorySidebarFeature: Sendable {
  public typealias Category = Domain.Category
  public init() {}

  /// categoryUseCase
  @Dependency(\.categoryUseCase) var categoryUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable {
    public init(
      isPresented: Bool = false,
      categoryList: [Category] = [],
      selectedCategory: Category? = nil
    ) {
      self.isPresented = isPresented
      self.categoryList = categoryList
      self.selectedCategory = selectedCategory
    }
    /// サイドバーの表示状態
    public var isPresented: Bool
    /// カテゴリリスト
    public var categoryList: [Category]
    /// 選択されているカテゴリ
    public var selectedCategory: Category?
    /// ページネーション用のnextToken
    public var nextToken: String?
    /// ページネーション読み込み中フラグ
    public var isLoadingMore: Bool = false
    /// 初期読み込み完了フラグ
    public var isLoaded: Bool = false
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
      /// 背景タップ
      case backgroundTapped
      /// 閉じるボタンタップ
      case closeButtonTapped
      /// カテゴリタップ
      case categoryTapped(Category?)
      /// サイドバー表示時
      case onAppear
      /// さらに読み込み
      case loadMore
    }

    public enum InternalAction: Equatable {
      /// カテゴリ取得
      case fetchCategories
      /// カテゴリ取得レスポンス
      case fetchCategoriesResponse([Category], nextToken: String?)
      /// さらにカテゴリを取得
      case fetchMoreCategories
      /// さらにカテゴリを取得レスポンス
      case fetchMoreCategoriesResponse([Category], nextToken: String?)
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// サイドバーを閉じる
      case dismiss
      /// カテゴリ選択
      case selectCategory(Category?)
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .backgroundTapped, .closeButtonTapped:
          state.isPresented = false
          return .send(.delegate(.dismiss))

        case .categoryTapped(let category):
          state.selectedCategory = category
          state.isPresented = false
          return .concatenate(
            .send(.delegate(.dismiss)),
            .send(.delegate(.selectCategory(category)))
          )

        case .onAppear:
          if !state.isLoaded {
            state.isLoaded = true
            return .send(.internal(.fetchCategories))
          }
          return .none

        case .loadMore:
          if !state.isLoadingMore && state.nextToken != nil {
            state.isLoadingMore = true
            return .send(.internal(.fetchMoreCategories))
          }
          return .none
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchCategories:
          return .run(
            operation: { send in
              let result = try await categoryUseCase.fetch(limit: 20)
              await send(.internal(.fetchCategoriesResponse(result.items, nextToken: result.nextToken)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .fetchCategoriesResponse(let categories, let nextToken):
          state.categoryList = categories
          state.nextToken = nextToken
          return .none

        case .fetchMoreCategories:
          guard let nextToken = state.nextToken else {
            state.isLoadingMore = false
            return .none
          }
          return .run(
            operation: { send in
              let result = try await categoryUseCase.fetchMore(nextToken: nextToken, limit: 20)
              await send(.internal(.fetchMoreCategoriesResponse(result.items, nextToken: result.nextToken)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .fetchMoreCategoriesResponse(let categories, let nextToken):
          state.categoryList.append(contentsOf: categories)
          state.nextToken = nextToken
          state.isLoadingMore = false
          return .none

        case .handleError(let errorInfo):
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
