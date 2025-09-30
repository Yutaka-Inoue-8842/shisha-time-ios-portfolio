//
//  AddDocumentFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/20.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// ドキュメント作成画面
@Reducer
public struct AddDocumentFeature: Sendable {
  public typealias Category = Domain.Category
  public init() {}

  /// documentUseCase
  @Dependency(\.documentUseCase) var documentUseCase
  /// categoryUseCase
  @Dependency(\.categoryUseCase) var categoryUseCase
  /// dismiss
  @Dependency(\.dismiss) var dismiss
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    public init(selectedCategory: Category? = nil) {
      self.selectedCategory = selectedCategory
    }
    /// 入力された内容
    var content: NSAttributedString = NSAttributedString(string: "")
    /// 選択されたカテゴリ
    var selectedCategory: Category?
    /// カテゴリリスト
    var categoryList: [Category] = []
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
      /// Backをタップ
      case backButtonTapped
      /// カテゴリを選択
      case categorySelected(Category?)
    }

    public enum InternalAction: Equatable {
      /// ドキュメントを保存
      case save
      /// カテゴリ取得
      case fetchCategories
      /// カテゴリ取得レスポンス
      case fetchCategoriesResponse([Category])
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// タイマー追加
      case addDocument(Document)
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          return .send(.internal(.fetchCategories))

        case .saveButtonTapped:
          return .send(.internal(.save))

        case .backButtonTapped:
          return .send(.internal(.save))

        case .categorySelected(let category):
          state.selectedCategory = category
          return .none
        }

      case .internal(let internalAction):
        switch internalAction {
        case .save:
          return .run(
            operation: { [state] send in
              // 内容があれば更新
              if !state.content.string.isEmpty {
                let result = try await documentUseCase.create(
                  content: state.content,
                  category: state.selectedCategory
                )
                await send(.delegate(.addDocument(result)))
              }
              await dismiss()
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .fetchCategories:
          return .run(
            operation: { send in
              let result = try await categoryUseCase.fetch(limit: 20)
              await send(.internal(.fetchCategoriesResponse(result.items)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .fetchCategoriesResponse(let categories):
          state.categoryList = categories
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
