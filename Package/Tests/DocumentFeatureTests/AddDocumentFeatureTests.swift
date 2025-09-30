//
//  AddDocumentFeatureTests.swift
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
struct AddDocumentFeatureTests {
  typealias Feature = AddDocumentFeature
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
  func testStateInitialization_withoutCategory() async {
    let state = Feature.State()

    #expect(state.content.string.isEmpty)
    #expect(state.selectedCategory == nil)
    #expect(state.categoryList.isEmpty)
  }

  @Test @MainActor
  func testStateInitialization_withCategory() async {
    let category = createCategory(name: "テストカテゴリ")
    let state = Feature.State(selectedCategory: category)

    #expect(state.content.string.isEmpty)
    #expect(state.selectedCategory == category)
    #expect(state.categoryList.isEmpty)
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testFetchCategoriesResponse_setsList() async {
    let categories = [
      createCategory(name: "カテゴリ1"),
      createCategory(name: "カテゴリ2")
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchCategoriesResponse(categories))) {
      $0.categoryList = categories
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

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_fetchesCategories() async {
    let categories = [
      createCategory(),
      createCategory()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { _ in
        .init(items: categories, nextToken: "nextToken")
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchCategories))
    await store.receive(.internal(.fetchCategoriesResponse(categories))) {
      $0.categoryList = categories
    }
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_onFailure_reportsError() async {
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchCategories))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_triggersInternalSave() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.save))
    await store.finish()
  }

  @Test @MainActor
  func testBackButtonTapped_triggersInternalSave() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.backButtonTapped))
    await store.receive(.internal(.save))
    await store.finish()
  }

  @Test @MainActor
  func testCategorySelected_updatesSelectedCategory() async {
    let category = createCategory()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.categorySelected(category))) {
      $0.selectedCategory = category
    }
    await store.finish()
  }

  @Test @MainActor
  func testCategorySelected_withNil_clearsSelectedCategory() async {
    let category = createCategory()
    var initialState = Feature.State()
    initialState.selectedCategory = category

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.categorySelected(nil))) {
      $0.selectedCategory = nil
    }
    await store.finish()
  }

  // MARK: - 内部アクション：save

  @Test @MainActor
  func testSave_withEmptyContent_dismissesWithoutCreating() async {
    var dismissCalled = false
    let createDocument = createDocument()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.create = { _, _ in
        return createDocument
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withContent_createsDocumentAndDismisses() async {
    let content = "テストドキュメント内容"
    let category = createCategory()
    let createdDocument = createDocument(content: content, text: content)
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.content = NSAttributedString(string: content)
    initialState.selectedCategory = category

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.create = { passedContent, passedCategory in
        #expect(passedContent.string == content)
        #expect(passedCategory == category)
        return createdDocument
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.addDocument(createdDocument)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withContentButNoCategory_createsDocumentWithNilCategory() async {
    let content = "テストドキュメント内容"
    let createdDocument = createDocument(content: content, text: content)
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.content = NSAttributedString(string: content)
    initialState.selectedCategory = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.create = { passedContent, passedCategory in
        #expect(passedContent.string == content)
        #expect(passedCategory == nil)
        return createdDocument
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.addDocument(createdDocument)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_onFailure_reportsErrorWithoutDismissing() async {
    let content = "テストドキュメント内容"
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.content = NSAttributedString(string: content)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.create = { _, _ in
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

  // MARK: - 内部アクション：fetchCategories

  @Test @MainActor
  func testFetchCategories_callsUseCaseAndSetsResponse() async {
    let categories = [
      createCategory(),
      createCategory()
    ]

    let store = TestStore(initialState: Feature.State()) {
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
    await store.finish()
  }

  @Test @MainActor
  func testFetchCategories_onFailure_reportsError() async {
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
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

  // MARK: - Bindingアクション
  // NSAttributedStringがSendableに準拠していないためコメントアウト

  //  @Test @MainActor
  //  func testBinding_updatesContent() async {
  //    let newContent = NSAttributedString(string: "新しい内容")
  //
  //    let store = TestStore(initialState: Feature.State()) {
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
    let category = createCategory()

    let store = TestStore(initialState: Feature.State()) {
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

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.delegate(.addDocument(document)))
    await store.finish()
  }
}
