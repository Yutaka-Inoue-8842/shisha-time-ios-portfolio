//
//  AddTemplateFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// テンプレート追加画面
@Reducer
public struct AddTemplateFeature: Sendable {
  public init() {}

  /// TemplateUseCase
  @Dependency(\.templateUseCase) var templateUseCase
  /// dismiss
  @Dependency(\.dismiss) var dismiss
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    public init() {}
    /// テンプレートタイトル
    var title: String = ""
    /// 入力された内容
    var content: NSAttributedString = NSAttributedString(string: "")
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
    }

    public enum InternalAction: Equatable {
      /// テンプレートを保存
      case save
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// テンプレート追加
      case addTemplate(Template)
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
        }

      case .internal(let internalAction):
        switch internalAction {
        case .save:
          return .run(
            operation: { [state] send in
              // 内容があれば更新
              if !state.title.isEmpty {
                let result = try await templateUseCase.create(
                  title: state.title,
                  content: state.content
                )
                await send(.delegate(.addTemplate(result)))
              }
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
