//
//  DocumentListFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/04.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import SettingFeature

/// ドキュメント一覧画面
@Reducer
public struct DocumentListFeature: Sendable {
  public typealias Category = Domain.Category
  public init() {}

  /// documentUseCase
  @Dependency(\.documentUseCase) var documentUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable, @unchecked Sendable {
    public init() {}
    /// ドキュメントリスト
    public var documentList: [Document] = []
    /// 初期読み込み完了フラグ
    public var isLoaded: Bool = false
    /// ページネーション用のnextToken
    public var nextToken: String?
    /// ページネーション読み込み中フラグ
    var isLoadingMore: Bool = false
    /// 画面遷移のState
    @Presents var destination: Destination.State?
    /// 選択されているカテゴリ
    public var selectedCategory: Category?
    /// 検索クエリ
    var searchQuery: String = ""
  }

  public enum Action: ViewAction, BindableAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// bindingアクション
    case binding(BindingAction<State>)
    /// 子画面への委譲アクション
    case delegate(Delegate)
    /// 子画面のアクション
    case destination(PresentationAction<Destination.Action>)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// さらに読み込み
      case loadMore
      /// ドキュメントタップ
      case documentTapped(Document)
      /// 追加ボタンタップ
      case addButtonTapped
      /// リストスワイプで削除
      case swipeToDelete(Document)
      /// セッティングをタップ
      case settingButtonTapped
      /// ハンバーガーメニューをタップ
      case hamburgerMenuTapped
      /// カテゴリ選択
      case categorySelected(Category?)
    }

    public enum InternalAction: Equatable {
      /// ドキュメント取得
      case fetchDocument
      /// ドキュメント取得レスポンス
      case fetchDocumentResponse([Document], String?)
      /// さらにドキュメント取得実行
      case fetchMoreDocument
      /// さらにドキュメント取得レスポンス
      case fetchMoreDocumentResponse([Document], String?)
      /// ステートの配列にドキュメントを追加
      case addDocument(Document)
      /// ステートの配列からドキュメントを更新
      case updateDocument(Document)
      /// ステートの配列からドキュメントを削除
      case deleteDocument(Document)
      /// 検索実行
      case performSearch
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }

    public enum Delegate: Equatable {
      /// ハンバーガーメニューをタップ
      case hamburgerMenuTapped
    }
  }

  // タスクキャンセル用のID
  enum CancelID {
    // UseCase
    case usecase
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          if !state.isLoaded {
            return .send(.internal(.fetchDocument))
          }
          return .none

        case .loadMore:
          guard !state.isLoadingMore,
            let nextToken = state.nextToken
          else {
            return .none
          }
          state.isLoadingMore = true

          // 検索中の場合は検索用のfetchMoreを使用
          if !state.searchQuery.isEmpty {
            return .run(
              operation: { [state] send in
                let result: PaginatedList<Document>

                if let category = state.selectedCategory {
                  // カテゴリ絞り込み中：カテゴリ内で検索
                  result = try await documentUseCase.searchMoreByCategory(
                    query: state.searchQuery,
                    category: category,
                    nextToken: nextToken,
                    limit: 20
                  )
                } else {
                  // 全体検索
                  result = try await documentUseCase.searchMore(
                    query: state.searchQuery,
                    nextToken: nextToken,
                    limit: 20
                  )
                }

                await send(.internal(.fetchMoreDocumentResponse(result.items, result.nextToken)))
              },
              catch: { error, send in
                let errorInfo = error.toErrorInfo()
                await send(.internal(.handleError(errorInfo)))
              }
            )
            .cancellable(
              id: CancelID.usecase,
              cancelInFlight: true
            )
          } else {
            return .send(.internal(.fetchMoreDocument))
          }

        case .documentTapped(let document):
          state.destination = .editDocument(
            .init(
              document: document
            )
          )
          return .none

        case .addButtonTapped:
          // 遷移処理　ドキュメント追加画面へ
          state.destination = .addDocument(.init(selectedCategory: state.selectedCategory))
          return .none

        case .swipeToDelete(let timer):
          return .run(
            operation: { send in
              try await documentUseCase.delete(timer)
              await send(.internal(.deleteDocument(timer)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .settingButtonTapped:
          state.destination = .settingMenu(.init())
          return .none

        case .hamburgerMenuTapped:
          return .send(.delegate(.hamburgerMenuTapped))

        case .categorySelected(let category):
          state.selectedCategory = category
          state.nextToken = nil
          state.documentList = []

          return .run(
            operation: { send in
              let result: PaginatedList<Document>
              if let category = category {
                result = try await documentUseCase.fetchByCategory(category: category, limit: 20)
              } else {
                result = try await documentUseCase.fetch(limit: 20)
              }
              await send(.internal(.fetchDocumentResponse(result.items, result.nextToken)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
          .cancellable(
            id: CancelID.usecase,
            cancelInFlight: true
          )
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchDocument:
          state.nextToken = nil
          state.isLoadingMore = false
          return .run(
            operation: { send in
              let result = try await documentUseCase.fetch(limit: 20)
              await send(.internal(.fetchDocumentResponse(result.items, result.nextToken)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
          .cancellable(
            id: CancelID.usecase,
            cancelInFlight: true
          )

        case .fetchDocumentResponse(let documents, let nextToken):
          state.isLoaded = true
          state.documentList = documents
          state.nextToken = nextToken
          return .none

        case .fetchMoreDocument:
          guard let token = state.nextToken else {
            state.isLoadingMore = false
            return .none
          }

          return .run(
            operation: { [selectedCategory = state.selectedCategory] send in
              let result: PaginatedList<Document>
              if let category = selectedCategory {
                result = try await documentUseCase.fetchMoreByCategory(category: category, nextToken: token, limit: 20)
              } else {
                result = try await documentUseCase.fetchMore(nextToken: token, limit: 20)
              }
              await send(.internal(.fetchMoreDocumentResponse(result.items, result.nextToken)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
          .cancellable(
            id: CancelID.usecase,
            cancelInFlight: true
          )

        case .fetchMoreDocumentResponse(let moreDocuments, let nextToken):
          state.isLoadingMore = false
          state.documentList.append(contentsOf: moreDocuments)
          state.nextToken = nextToken
          return .none

        case .addDocument(let document):
          // 一番上にドキュメント追加
          state.documentList.insert(document, at: 0)
          return .none

        case .updateDocument(let document):
          // ドキュメントを更新
          if let index = state.documentList.firstIndex(where: { $0.id == document.id }) {
            state.documentList.remove(at: index)

            // カテゴリフィルタリング中で、更新されたドキュメントのカテゴリが異なる場合は削除のみ
            return .run { [selectedCategory = state.selectedCategory] send in
              let documentCategory = try await document.category

              // 選択中のカテゴリと更新されたドキュメントのカテゴリが一致する場合のみリストに追加
              let shouldKeepInList: Bool
              if let selectedCategory = selectedCategory {
                shouldKeepInList = documentCategory?.id == selectedCategory.id
              } else {
                // 「すべて」が選択されている場合は常にリストに追加
                shouldKeepInList = true
              }

              if shouldKeepInList {
                await send(.internal(.addDocument(document)))
              }
            }
          }
          return .none

        case .deleteDocument(let document):
          // ドキュメント削除
          if let index = state.documentList.firstIndex(where: { $0.id == document.id }) {
            state.documentList.remove(at: index)
          }
          return .none

        case .performSearch:
          // 検索クエリが空の場合は通常の取得処理を実行
          if state.searchQuery.isEmpty {
            return .send(.internal(.fetchDocument))
          }

          // サーバーサイド検索処理
          return .run(
            operation: { [searchQuery = state.searchQuery, selectedCategory = state.selectedCategory] send in
              let result: PaginatedList<Document>

              if let category = selectedCategory {
                // カテゴリ絞り込み中：カテゴリ内で検索
                result = try await documentUseCase.searchByCategory(query: searchQuery, category: category, limit: 20)
              } else {
                // 全体検索
                result = try await documentUseCase.search(query: searchQuery, limit: 20)
              }

              await send(.internal(.fetchDocumentResponse(result.items, result.nextToken)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
          .cancellable(
            id: CancelID.usecase,
            cancelInFlight: true
          )

        case .handleError(let errorInfo):
          errorHandler.send(errorInfo)
          return .none
        }

      case .destination(.presented(.addDocument(.delegate(.addDocument(let document))))):
        return .run { send in
          try await Task.sleep(for: .seconds(0.6))
          await send(.internal(.addDocument(document)))
        }

      case .destination(.presented(.editDocument(.delegate(.updateDocument(let document))))):
        return .run { send in
          try await Task.sleep(for: .seconds(0.6))
          await send(.internal(.updateDocument(document)))
        }

      case .binding(\.searchQuery):
        return .send(.internal(.performSearch))
          .debounce(id: "search", for: 0.3, scheduler: DispatchQueue.main)

      case .binding:
        return .none

      case .delegate:
        return .none

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension DocumentListFeature {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    // ドキュメント追加画面
    case addDocument(AddDocumentFeature)
    // ドキュメント編集画面
    case editDocument(EditDocumentFeature)
    // 設定メニュー画面
    case settingMenu(SettingMenuFeature)
  }
}
