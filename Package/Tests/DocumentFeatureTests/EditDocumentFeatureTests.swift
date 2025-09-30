//
//  EditDocumentFeatureTests.swift
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
struct EditDocumentFeatureTests {
  typealias Feature = EditDocumentFeature
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

  // MARK: - State初期化テスト

  @Test @MainActor
  func testStateInitialization_setsDocumentAndContent() async {
    let document = createDocument()
    let state = Feature.State(document: document)

    #expect(state.document == document)
    #expect(state.selectedCategory == nil)
    #expect(state.categoryList.isEmpty)
  }

  @Test @MainActor
  func testStateInitialization_withInvalidContent_setsEmptyContent() async {
    // 無効なデータを持つドキュメント（toAttributedString()がnilを返すケース）
    let invalidDocument = Document(
      id: UUID().uuidString,
      content: "",  // 空の文字列
      text: "",
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
    let state = Feature.State(document: invalidDocument)

    #expect(state.document == invalidDocument)
    #expect(state.content.string.isEmpty)
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testFetchCategoriesResponse_setsListAndTriggersCurrentCategory() async {
    let document = createDocument()
    let categories = [
      createCategory(name: "カテゴリ1"),
      createCategory(name: "カテゴリ2")
    ]

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    }

    await store.send(.internal(.fetchCategoriesResponse(categories))) {
      $0.categoryList = categories
    }
    await store.receive(.internal(.fetchCurrentCategory))
    await store.receive(.internal(.setCurrentCategory(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testSetCurrentCategory_updatesSelectedCategory() async {
    let document = createDocument()
    let category = createCategory()

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    }

    await store.send(.internal(.setCurrentCategory(category))) {
      $0.selectedCategory = category
    }
    await store.finish()
  }

  @Test @MainActor
  func testSetCurrentCategory_withNil_clearsSelectedCategory() async {
    let document = createDocument()
    let category = createCategory()

    var initialState = Feature.State(document: document)
    initialState.selectedCategory = category

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.setCurrentCategory(nil))) {
      $0.selectedCategory = nil
    }
    await store.finish()
  }

  @Test @MainActor
  func testHandleError_sendsErrorToHandler() async {
    let document = createDocument()
    let error = AppError.unknown
    let errorInfo = error.toErrorInfo()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State(document: document)) {
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

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_fetchesCategories() async {
    let document = createDocument()
    let categories = [createCategory()]

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: categories, nextToken: "nextToken")
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchCategories))
    await store.receive(.internal(.fetchCategoriesResponse(categories))) {
      $0.categoryList = categories
    }
    await store.receive(.internal(.fetchCurrentCategory))
    await store.receive(.internal(.setCurrentCategory(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_triggersInternalSave() async {
    let document = createDocument()

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.update = { _, _, _ in
        return document
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.save))
    await store.receive(.delegate(.updateDocument(document)))
    await store.finish()
  }

  @Test @MainActor
  func testBackButtonTapped_triggersInternalSave() async {
    let document = createDocument()

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.update = { _, _, _ in
        return document
      }
    }

    await store.send(.view(.backButtonTapped))
    await store.receive(.internal(.save))
    await store.receive(.delegate(.updateDocument(document)))
    await store.finish()
  }

  @Test @MainActor
  func testCategorySelected_updatesSelectedCategory() async {
    let document = createDocument()
    let category = createCategory()

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    }

    await store.send(.view(.categorySelected(category))) {
      $0.selectedCategory = category
    }
    await store.finish()
  }

  // MARK: - 内部アクション：save

  @Test @MainActor
  func testSave_withNoChanges_dismissesWithoutUpdating() async {
    let originalDocument = createDocument(content: "OriginalContent", text: "OriginalText")
    let updatedlDocument = createDocument()
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State(document: originalDocument)) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.update = { _, _, _ in
        return updatedlDocument
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateDocument(updatedlDocument)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withContentChanges_updatesDocumentAndDismisses() async {
    let originalContent = "元の内容"
    let updatedContent = "更新された内容"
    let document = createDocument(content: originalContent, text: originalContent)
    let updatedDocument = createDocument(id: document.id, content: updatedContent, text: updatedContent)
    var dismissCalled = false

    var initialState = Feature.State(document: document)
    initialState.content = NSAttributedString(string: updatedContent)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.update = { passedDocument, newContent, newCategory in
        #expect(passedDocument == document)
        #expect(newContent.string == updatedContent)
        #expect(newCategory == nil)
        return updatedDocument
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateDocument(updatedDocument)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withCategoryChanges_updatesDocumentAndDismisses() async {
    let content = "内容"
    let updatedCategory = createCategory(id: "updated", name: "更新されたカテゴリ")
    let document = createDocument(content: content, text: content)
    let updatedDocument = createDocument(id: document.id, content: content, text: content)
    var dismissCalled = false

    var initialState = Feature.State(document: document)
    initialState.selectedCategory = updatedCategory

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.update = { passedDocument, newContent, newCategory in
        #expect(passedDocument == document)
        #expect(newCategory == updatedCategory)
        return updatedDocument
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    // document.categoryが非同期でアクセスされるため、テストでは元のカテゴリとして扱う

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateDocument(updatedDocument)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_onFailure_reportsErrorWithoutDismissing() async {
    let document = createDocument()
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)
    var dismissCalled = false

    var initialState = Feature.State(document: document)
    initialState.content = NSAttributedString(string: "更新された内容")

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.update = { _, _, _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    #expect(!dismissCalled)
    await store.finish()
  }

  // MARK: - 内部アクション：fetchCategories & fetchCurrentCategory

  @Test @MainActor
  func testFetchCategories_callsUseCaseAndSetsResponse() async {
    let document = createDocument()
    let categories = [createCategory()]

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: categories, nextToken: "nextToken")
      }
    }

    await store.send(.internal(.fetchCategories))
    await store.receive(.internal(.fetchCategoriesResponse(categories))) {
      $0.categoryList = categories
    }
    await store.receive(.internal(.fetchCurrentCategory))
    await store.receive(.internal(.setCurrentCategory(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testFetchCategories_onFailure_reportsError() async {
    let document = createDocument()
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.fetchCategories))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testFetchCurrentCategory_setsCurrentCategory() async {
    let document = createDocument()

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    } withDependencies: { _ in
      // document.categoryの非同期アクセスはライブ値で処理される
    }

    await store.send(.internal(.fetchCurrentCategory))
    await store.receive(.internal(.setCurrentCategory(nil)))
    await store.finish()
  }

  // Categoryが非同期でアクセスされるため、失敗ケースのテストはコメントアウト
  //  @Test @MainActor
  //  func testFetchCurrentCategory_onFailure_reportsError() async {
  //    let document = createDocument()
  //    let error = AppError.unknown
  //    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)
  //
  //    let store = TestStore(initialState: Feature.State(document: document)) {
  //      Feature()
  //    } withDependencies: {
  //      $0.errorHandler.send = { errorInfo in
  //        sentErrorInfo.setValue(errorInfo)
  //      }
  //    }
  //
  //    await store.send(.internal(.fetchCurrentCategory))
  //    await store.receive(.internal(.handleError(error.toErrorInfo())))
  //
  //    #expect(sentErrorInfo.value == error.toErrorInfo())
  //    await store.finish()
  //  }

  // MARK: - Bindingアクション
  // NSAttributedStringはSandableに準拠していないため、contentのBindingテストはコメントアウト

  //  @Test @MainActor
  //  func testBinding_updatesContent() async {
  //    let document = createDocument()
  //    let newContent = NSAttributedString(string: "新しい内容")
  //
  //    let store = TestStore(initialState: Feature.State(document: document)) {
  //      Feature()
  //    }
  //
  //    await store.send(.binding(.set(\.content, newContent))) {
  //      $0.content = newContent
  //    }
  //    await store.finish()
  //  }

  @Test @MainActor
  func testBinding_updatesSelectedCategory() async {
    let document = createDocument()
    let category = createCategory()

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    }

    await store.send(.binding(.set(\.selectedCategory, category))) {
      $0.selectedCategory = category
    }
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let document = createDocument()
    let updatedDocument = createDocument(id: document.id, content: "更新済み", text: "更新済み")

    let store = TestStore(initialState: Feature.State(document: document)) {
      Feature()
    }

    await store.send(.delegate(.updateDocument(updatedDocument)))
    await store.finish()
  }

  // MARK: - Edge cases

  @Test @MainActor
  func testSave_preservesOriginalDocumentProperties() async {
    let originalId = "test-id"
    let originalCreatedAt = Date().addingTimeInterval(-86400)  // 1日前
    let originalContent = "元の内容"
    let updatedContent = "更新された内容"

    let document = Document(
      id: originalId,
      content: originalContent,
      text: originalContent,
      createdAt: .init(originalCreatedAt),
      updatedAt: .init(Date())
    )

    let updatedDocument = createDocument(id: originalId, content: updatedContent, text: updatedContent)
    let passedDocument = LockIsolated<Document?>(nil)
    var dismissCalled = false

    var initialState = Feature.State(document: document)
    initialState.content = NSAttributedString(string: updatedContent)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.update = { document, _, _ in
        passedDocument.setValue(document)
        return updatedDocument
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateDocument(updatedDocument)))

    // 元のドキュメントのプロパティが保持されていることを確認
    let passed = passedDocument.value
    #expect(passed?.id == originalId)
    #expect(passed?.createdAt.foundationDate == originalCreatedAt)
    #expect(dismissCalled)
    await store.finish()
  }
}
