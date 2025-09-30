//
//  DocumentListFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/26.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import Testing

@testable import DocumentFeature

@MainActor
struct DocumentListFeatureTests {
  typealias Feature = DocumentListFeature
  typealias Category = Feature.Category

  // MARK: - Mock Data Creation

  private func createCategory(id: String = UUID().uuidString, name: String = "カテゴリ") -> Category {
    Category(
      id: id,
      name: name,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  private func createDocument(
    id: String = UUID().uuidString,
    content: String = "テストドキュメント",
    text: String = "テストドキュメント",
    category: Category? = nil
  ) -> Document {
    Document(
      id: id,
      content: content,
      text: text,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testFetchDocumentResponse_setsListAndState() async {
    let documents = [
      createDocument(),
      createDocument()
    ]
    let nextToken = "nextToken"

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchDocumentResponse(documents, nextToken))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = nextToken
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreDocumentResponse_appendsAndUpdatesState() async {
    let initialDocuments = [createDocument(id: "1")]
    let moreDocuments = [createDocument(id: "2"), createDocument(id: "3")]
    let nextToken = "nextToken"

    var initialState = Feature.State()
    initialState.documentList = initialDocuments
    initialState.isLoadingMore = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.fetchMoreDocumentResponse(moreDocuments, nextToken))) {
      $0.isLoadingMore = false
      $0.documentList = initialDocuments + moreDocuments
      $0.nextToken = nextToken
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddDocument_insertsAtBeginning() async {
    let existingDocument = createDocument(id: "existing")
    let newDocument = createDocument(id: "new")

    var initialState = Feature.State()
    initialState.documentList = [existingDocument]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.addDocument(newDocument))) {
      $0.documentList = [newDocument, existingDocument]
    }
    await store.finish()
  }

  @Test @MainActor
  func testUpdateDocument_replacesMatchedItem() async {
    let id = UUID().uuidString
    let beforeDocument = createDocument(id: id, content: "Before", text: "Before")
    let afterDocument = createDocument(id: id, content: "After", text: "After")
    var initialState = Feature.State()
    initialState.documentList = [beforeDocument]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      // document.category を読み取るためのモック
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.internal(.updateDocument(afterDocument))) {
      $0.documentList = []
    }
    await store.receive(.internal(.addDocument(afterDocument))) {
      $0.documentList = [afterDocument]
    }
    await store.finish()
  }

  @Test @MainActor
  func testDeleteDocument_removesMatchedItem() async {
    let documents = [
      createDocument(id: "1"),
      createDocument(id: "2")
    ]
    var initialState = Feature.State()
    initialState.documentList = documents

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteDocument(documents[0]))) {
      $0.documentList = [documents[1]]
    }
    await store.finish()
  }

  @Test @MainActor
  func testPerformSearch_withEmptyQuery_triggersFetchDocument() async {
    let documents = [
      createDocument(id: "1"),
      createDocument(id: "2")
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetch = { limit in
        return .init(items: documents, nextToken: "nextToken")
      }
    }

    await store.send(.internal(.performSearch))
    await store.receive(.internal(.fetchDocument))
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testHandleError_sendsErrorToHandler() async {
    let error = AppError.unknown
    let errorInfo = error.toErrorInfo()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.handleError(errorInfo)))

    #expect(sentErrorInfo.value == errorInfo)
    await store.finish()
  }

  // MARK: - Viewアクション（初期表示・データ取得）

  @Test @MainActor
  func testOnAppear_whenNotLoaded_fetchesDocuments() async {
    let documents = [
      createDocument(),
      createDocument()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: documents, nextToken: "nextToken")
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchDocument))
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_whenAlreadyLoaded_doesNothing() async {
    var initialState = Feature.State()
    initialState.isLoaded = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.onAppear))
    await store.finish()
  }

  // MARK: - Viewアクション（ナビゲーション）

  @Test @MainActor
  func testAddButtonTapped_presentsAddScreen() async {
    let category = createCategory()
    var initialState = Feature.State()
    initialState.selectedCategory = category

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addDocument(.init(selectedCategory: category))
    }
    await store.finish()
  }

  @Test @MainActor
  func testDocumentTapped_presentsEditScreen() async {
    let document = createDocument()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.documentTapped(document))) {
      $0.destination = .editDocument(.init(document: document))
    }
    await store.finish()
  }

  @Test @MainActor
  func testSettingButtonTapped_presentsSettingMenu() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.settingButtonTapped)) {
      $0.destination = .settingMenu(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testHamburgerMenuTapped_sendsDelegate() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.hamburgerMenuTapped))
    await store.receive(.delegate(.hamburgerMenuTapped))
    await store.finish()
  }

  // MARK: - Viewアクション（カテゴリ選択）

  @Test @MainActor
  func testCategorySelected_withCategory_fetchesByCategory() async {
    let category = createCategory()
    let documents = [createDocument()]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetchByCategory = { passedCategory, limit in
        #expect(passedCategory == category)
        #expect(limit == 20)
        return .init(items: documents, nextToken: "nextToken")
      }
    }

    await store.send(.view(.categorySelected(category))) {
      $0.selectedCategory = category
      $0.nextToken = nil
      $0.documentList = []
    }
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testCategorySelected_withNil_fetchesAll() async {
    let category = createCategory()
    let documents = [createDocument()]

    var initialState = Feature.State()
    initialState.selectedCategory = category

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: documents, nextToken: "nextToken")
      }
    }

    await store.send(.view(.categorySelected(nil))) {
      $0.selectedCategory = nil
      $0.nextToken = nil
      $0.documentList = []
    }
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  // MARK: - Viewアクション（削除）

  @Test @MainActor
  func testSwipeToDelete_callsUseCaseAndRemovesOnSuccess() async {
    let document = createDocument()
    let deletedDocument = LockIsolated<Document?>(nil)
    var initialState = Feature.State()
    initialState.documentList = [document]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.delete = { document in
        deletedDocument.setValue(document)
      }
    }

    await store.send(.view(.swipeToDelete(document)))
    await store.receive(.internal(.deleteDocument(document))) {
      $0.documentList = []
    }

    #expect(deletedDocument.value == document)
    await store.finish()
  }

  @Test @MainActor
  func testSwipeToDelete_onFailure_reportsErrorAndKeepsState() async {
    let error = AppError.unknown
    let document = createDocument()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)
    var initialState = Feature.State()
    initialState.documentList = [document]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.delete = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.swipeToDelete(document)))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(store.state.documentList == [document])
    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  // MARK: - Viewアクション（ページネーション）

  @Test @MainActor
  func testLoadMore_whenNotLoadingAndHasToken_fetchesMore() async {
    let existingDocuments = [createDocument(id: "1")]
    let moreDocuments = [createDocument(id: "2")]

    var initialState = Feature.State()
    initialState.documentList = existingDocuments
    initialState.nextToken = "nextToken"
    initialState.isLoadingMore = false

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetchMore = { nextToken, limit in
        #expect(nextToken == "nextToken")
        #expect(limit == 20)
        return .init(items: moreDocuments, nextToken: "newToken")
      }
    }

    await store.send(.view(.loadMore)) {
      $0.isLoadingMore = true
    }
    await store.receive(.internal(.fetchMoreDocument))
    await store.receive(.internal(.fetchMoreDocumentResponse(moreDocuments, "newToken"))) {
      $0.isLoadingMore = false
      $0.documentList = existingDocuments + moreDocuments
      $0.nextToken = "newToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_whenAlreadyLoading_doesNothing() async {
    var initialState = Feature.State()
    initialState.isLoadingMore = true
    initialState.nextToken = "nextToken"

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.loadMore))
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_whenNoNextToken_doesNothing() async {
    var initialState = Feature.State()
    initialState.isLoadingMore = false
    initialState.nextToken = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.loadMore))
    await store.finish()
  }

  // MARK: - 内部アクション（fetch系）

  @Test @MainActor
  func testFetchDocument_callsUseCaseAndSetsResponse() async {
    let documents = [createDocument()]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: documents, nextToken: "nextToken")
      }
    }

    await store.send(.internal(.fetchDocument))
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchDocument_onFailure_reportsError() async {
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetch = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.fetchDocument))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreDocument_whenNoToken_stopsLoadingAndDoesNothing() async {
    var initialState = Feature.State()
    initialState.nextToken = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.fetchMoreDocument))
    await store.finish()
  }

  // MARK: - 検索機能のテスト

  @Test @MainActor
  func testPerformSearch_withQuery_performsSearch() async {
    let searchQuery = "テスト"
    let documents = [createDocument()]

    var initialState = Feature.State()
    initialState.searchQuery = searchQuery

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.search = { query, limit in
        #expect(query == searchQuery)
        #expect(limit == 20)
        return .init(items: documents, nextToken: "nextToken")
      }
    }

    await store.send(.internal(.performSearch))
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testPerformSearch_withQueryAndCategory_performsSearchByCategory() async {
    let searchQuery = "テスト"
    let category = createCategory()
    let documents = [createDocument()]

    var initialState = Feature.State()
    initialState.searchQuery = searchQuery
    initialState.selectedCategory = category

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.searchByCategory = { query, passedCategory, limit in
        #expect(query == searchQuery)
        #expect(passedCategory == category)
        #expect(limit == 20)
        return .init(items: documents, nextToken: "nextToken")
      }
    }

    await store.send(.internal(.performSearch))
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  // MARK: - 子画面 delegate → 親のinternalに変換されること

  @Test @MainActor
  func testAddDocumentDelegate_flowsToInternalAdd() async {
    let document = createDocument()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.continuousClock = TestClock()
    }

    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addDocument(.init())
    }
    await store.send(.destination(.presented(.addDocument(.delegate(.addDocument(document))))))
    await store.receive(.internal(.addDocument(document))) {
      $0.documentList = [document]
    }
    await store.finish()
  }

  @Test @MainActor
  func testEditDocumentDelegate_flowsToInternalUpdate() async {
    let originalDocument = createDocument(id: "test", content: "Original", text: "Original")
    let updatedDocument = createDocument(id: "test", content: "Updated", text: "Updated")

    var initialState = Feature.State()
    initialState.documentList = [originalDocument]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: { _ in
    }

    await store.send(.view(.documentTapped(originalDocument))) {
      $0.destination = .editDocument(.init(document: originalDocument))
    }
    await store.send(.destination(.presented(.editDocument(.delegate(.updateDocument(updatedDocument))))))
    await store.receive(.internal(.updateDocument(updatedDocument))) {
      $0.documentList = []
    }
    await store.receive(.internal(.addDocument(updatedDocument))) {
      $0.documentList = [updatedDocument]
    }
    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_searchQuery_triggersSearch() async {
    let errorInfo = AppError.unknown.toErrorInfo()
    let documents = [
      createDocument(id: "1"),
      createDocument(id: "2")
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.search = { _, _ in
        return .init(items: documents, nextToken: "nextToken")
      }
      $0.documentUseCase.searchByCategory = { _, _, _ in
        return .init(items: documents, nextToken: "nextToken")
      }

    }

    await store.send(.binding(.set(\.searchQuery, "テスト"))) {
      $0.searchQuery = "テスト"
    }
    await store.receive(.internal(.performSearch))
    await store.receive(.internal(.fetchDocumentResponse(documents, "nextToken"))) {
      $0.isLoaded = true
      $0.documentList = documents
      $0.nextToken = "nextToken"
    }

    await store.finish()
  }

  // MARK: - Edge cases

  @Test @MainActor
  func testUpdateDocument_whenItemNotFound_keepsOriginalState() async {
    let documents = [
      createDocument(id: "1"),
      createDocument(id: "2")
    ]
    let unrelatedDocument = createDocument(id: "3")

    var initialState = Feature.State()
    initialState.documentList = [documents[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
    }

    await store.send(.internal(.updateDocument(unrelatedDocument)))
    await store.finish()
  }

  @Test @MainActor
  func testDeleteDocument_whenItemNotFound_keepsOriginalState() async {
    let documents = [
      createDocument(id: "1"),
      createDocument(id: "2")
    ]
    let unrelatedDocument = createDocument(id: "3")

    var initialState = Feature.State()
    initialState.documentList = [documents[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteDocument(unrelatedDocument)))
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.delegate(.hamburgerMenuTapped))
    await store.finish()
  }
}
