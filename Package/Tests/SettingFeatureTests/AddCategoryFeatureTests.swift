//
//  AddCategoryFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/20.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import Testing

@testable import SettingFeature

@MainActor
struct AddCategoryFeatureTests {
  typealias Feature = AddCategoryFeature
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

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testSaveCategoryResponse_sendsDelegateAndDismisses() async {
    let category = createCategory()
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.saveCategoryResponse(category)))
    await store.receive(.delegate(.addCategory(category)))

    #expect(dismissCalled)
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
  func testOnAppear_doesNothing() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.onAppear))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_callsUseCaseAndSendsResponse() async {
    let categoryName = "テストカテゴリ"
    var initialState = Feature.State()
    initialState.categoryName = categoryName

    let createdCategory = createCategory(name: categoryName)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.create = { category in
        #expect(category.name == categoryName)
        return createdCategory
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.saveCategoryResponse(createdCategory)))
    await store.receive(.delegate(.addCategory(createdCategory)))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_trimsWhitespace() async {
    let categoryName = "  テストカテゴリ  "
    let trimmedName = "テストカテゴリ"
    var initialState = Feature.State()
    initialState.categoryName = categoryName

    let createdCategory = createCategory(name: trimmedName)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.create = { category in
        #expect(category.name == trimmedName)
        return createdCategory
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.saveCategoryResponse(createdCategory)))
    await store.receive(.delegate(.addCategory(createdCategory)))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_onFailure_reportsError() async {
    let error = AppError.unknown
    var initialState = Feature.State()
    initialState.categoryName = "テストカテゴリ"

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.create = { _ in
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.saveButtonTapped))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesCategoryName() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.binding(.set(\.categoryName, "新しいカテゴリ"))) {
      $0.categoryName = "新しいカテゴリ"
    }
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let category = createCategory()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.delegate(.addCategory(category)))
    await store.finish()
  }

  // MARK: - バリデーションエラーのテスト

  @Test @MainActor
  func testSaveButtonTapped_withValidationError_reportsError() async {
    var initialState = Feature.State()
    initialState.categoryName = ""  // 空文字でバリデーションエラー

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.create = { _ in
        throw CategoryValidationError.invalidNameEmpty
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.saveButtonTapped))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(CategoryValidationError.invalidNameEmpty.toErrorInfo())))

    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_withLongName_reportsError() async {
    let longName = String(repeating: "a", count: 30)  // 20文字超過
    var initialState = Feature.State()
    initialState.categoryName = longName

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.create = { _ in
        throw CategoryValidationError.invalidNameLength
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.saveButtonTapped))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(CategoryValidationError.invalidNameLength.toErrorInfo())))

    await store.finish()
  }
}
