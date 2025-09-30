//
//  TemplateListFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/11.
//

import Common
import ComposableArchitecture
import Domain
import Foundation

/// テンプレート一覧画面
@Reducer
public struct TemplateListFeature: Sendable {
  public init() {}

  /// templateUseCase
  @Dependency(\.templateUseCase) var templateUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    public init() {}
    /// すべてのドキュメントが格納されている配列
    var templateList: [Template] = []
    /// 初期読み込み完了フラグ
    var isLoaded: Bool = false
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
      /// テンプレートタップ
      case templateTapped(Template)
      /// 追加ボタンタップ
      case addButtonTapped
      /// リストスワイプで削除
      case swipeToDelete(Template)
    }

    public enum InternalAction: Equatable {
      ///  テンプレート取得
      case fetchAllTemplateResponse([Template])
      /// ステートの配列にテンプレートを追加
      case addTemplate(Template)
      /// ステートの配列からテンプレートを更新
      case updateTemplate(Template)
      /// ステートの配列からテンプレートを削除
      case deleteTemplate(Template)
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
            operation: { [state] send in
              if !state.isLoaded {
                // すべてのテンプレート取得
                let result = try await templateUseCase.fetchAll()
                await send(.internal(.fetchAllTemplateResponse(result)))
              }
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .templateTapped(let template):
          state.destination = .editTemplate(
            .init(
              template: template
            )
          )
          return .none

        case .addButtonTapped:
          state.destination = .addTemplate(.init())
          return .none

        case .swipeToDelete(let template):
          return .run(
            operation: { send in
              try await templateUseCase.delete(template)
              await send(.internal(.deleteTemplate(template)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchAllTemplateResponse(let result):
          state.isLoaded = true
          state.templateList = result
          return .none

        case .addTemplate(let template):
          // 一番上にテンプレート追加
          state.templateList.insert(template, at: 0)
          return .none

        case .updateTemplate(let template):
          // テンプレートを更新して一番上に追加
          if let index = state.templateList.firstIndex(where: { $0.id == template.id }) {
            state.templateList.remove(at: index)
            state.templateList.insert(template, at: 0)
          }
          return .none

        case .deleteTemplate(let template):
          // テンプレート削除
          if let index = state.templateList.firstIndex(where: { $0.id == template.id }) {
            state.templateList.remove(at: index)
          }
          return .none

        case .handleError(let errorInfo):
          errorHandler.send(errorInfo)
          return .none
        }

      case .destination(.presented(.addTemplate(.delegate(.addTemplate(let template))))):
        return .run { send in
          try await Task.sleep(for: .seconds(0.6))
          await send(.internal(.addTemplate(template)))
        }

      case .destination(.presented(.editTemplate(.delegate(.updateTemplate(let template))))):
        return .run { send in
          try await Task.sleep(for: .seconds(0.6))
          await send(.internal(.updateTemplate(template)))
        }

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension TemplateListFeature {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    // テンプレート追加画面
    case addTemplate(AddTemplateFeature)
    // テンプレート編集画面
    case editTemplate(EditTemplateFeature)
  }
}
