//
//  EditCategoryFeatureTests.swift
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
struct EditCategoryFeatureTests {
  typealias Feature = EditCategoryFeature
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

  // MARK: - State初期化テスト

  @Test @MainActor
  func testStateInitialization_setsCategoryAndName() async {
    let category = createCategory(name: "テストカテゴリ")
    let state = Feature.State(category: category)

    #expect(state.category == category)
    #expect(state.categoryName == "テストカテゴリ")
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testUpdateCategoryResponse_sendsDelegateAndDismisses() async {
    let originalCategory = createCategory(name: "オリジナル")
    let updatedCategory = createCategory(id: originalCategory.id, name: "更新済み")
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State(category: originalCategory)) {
      Feature()
    } withDependencies: {
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.updateCategoryResponse(updatedCategory)))
    await store.receive(.delegate(.updateCategory(updatedCategory)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testHandleError_sendsErrorToHandler() async {
    let category = createCategory()
    let error = AppError.unknown
    let errorInfo = error.toErrorInfo()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State(category: category)) {
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
    let category = createCategory()
    let store = TestStore(initialState: Feature.State(category: category)) {
      Feature()
    }

    await store.send(.view(.onAppear))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_callsUseCaseAndSendsResponse() async {
    let originalCategory = createCategory(name: "オリジナル")
    let updatedName = "更新されたカテゴリ"
    let updatedCategory = createCategory(id: originalCategory.id, name: updatedName)
    let updatedCategoryFromUseCase = LockIsolated<Category?>(nil)

    var initialState = Feature.State(category: originalCategory)
    initialState.categoryName = updatedName

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.update = { category in
        updatedCategoryFromUseCase.setValue(category)
        #expect(category.name == updatedName)
        #expect(category.id == originalCategory.id)
        return updatedCategory
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.updateCategoryResponse(updatedCategory)))
    await store.receive(.delegate(.updateCategory(updatedCategory)))

    // UseCaseに正しいカテゴリが渡されたことを確認
    #expect(updatedCategoryFromUseCase.value?.name == updatedName)
    #expect(updatedCategoryFromUseCase.value?.id == originalCategory.id)
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_trimsWhitespace() async {
    let originalCategory = createCategory(name: "オリジナル")
    let categoryNameWithWhitespace = "  更新されたカテゴリ  "
    let trimmedName = "更新されたカテゴリ"
    let updatedCategory = createCategory(id: originalCategory.id, name: trimmedName)

    var initialState = Feature.State(category: originalCategory)
    initialState.categoryName = categoryNameWithWhitespace

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.update = { category in
        #expect(category.name == trimmedName)
        return updatedCategory
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.updateCategoryResponse(updatedCategory)))
    await store.receive(.delegate(.updateCategory(updatedCategory)))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_preservesOriginalCategoryProperties() async {
    let originalCategory = createCategory(id: "test-id", name: "オリジナル")
    let updatedName = "更新されたカテゴリ"
    let updatedCategory = createCategory(id: "test-id", name: updatedName)
    let updatedCategoryFromUseCase = LockIsolated<Category?>(nil)

    var initialState = Feature.State(category: originalCategory)
    initialState.categoryName = updatedName

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.update = { category in
        updatedCategoryFromUseCase.setValue(category)
        return updatedCategory
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.updateCategoryResponse(updatedCategory)))
    await store.receive(.delegate(.updateCategory(updatedCategory)))

    // 元のカテゴリのプロパティが保持されていることを確認
    let passedCategory = updatedCategoryFromUseCase.value
    #expect(passedCategory?.id == originalCategory.id)
    #expect(passedCategory?.createdAt == originalCategory.createdAt)
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_onFailure_reportsError() async {
    let category = createCategory()
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State(category: category)
    initialState.categoryName = "更新されたカテゴリ"

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.update = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.saveButtonTapped))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesCategoryName() async {
    let category = createCategory()
    let store = TestStore(initialState: Feature.State(category: category)) {
      Feature()
    }

    await store.send(.binding(.set(\.categoryName, "新しいカテゴリ名"))) {
      $0.categoryName = "新しいカテゴリ名"
    }
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let category = createCategory()
    let updatedCategory = createCategory(id: category.id, name: "更新済み")

    let store = TestStore(initialState: Feature.State(category: category)) {
      Feature()
    }

    await store.send(.delegate(.updateCategory(updatedCategory)))
    await store.finish()
  }

  // MARK: - バリデーションエラーのテスト

  @Test @MainActor
  func testSaveButtonTapped_withValidationError_reportsError() async {
    let category = createCategory()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State(category: category)
    initialState.categoryName = ""  // 空文字でバリデーションエラー

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.update = { _ in
        throw CategoryValidationError.invalidNameEmpty
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.saveButtonTapped))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(CategoryValidationError.invalidNameEmpty.toErrorInfo())))

    #expect(sentErrorInfo.value == CategoryValidationError.invalidNameEmpty.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_withLongName_reportsError() async {
    let category = createCategory()
    let longName = String(repeating: "a", count: 30)  // 20文字超過
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State(category: category)
    initialState.categoryName = longName

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.update = { _ in
        throw CategoryValidationError.invalidNameLength
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.saveButtonTapped))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(CategoryValidationError.invalidNameLength.toErrorInfo())))

    #expect(sentErrorInfo.value == CategoryValidationError.invalidNameLength.toErrorInfo())
    await store.finish()
  }

  // MARK: - State変更なしのテスト

  @Test @MainActor
  func testSaveButtonTapped_withNoNameChange_stillCallsUseCase() async {
    let category = createCategory(name: "カテゴリ")
    let updatedCategoryFromUseCase = LockIsolated<Category?>(nil)
    let returnedCategory = createCategory(id: category.id, name: "カテゴリ")

    let store = TestStore(initialState: Feature.State(category: category)) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.update = { category in
        updatedCategoryFromUseCase.setValue(category)
        return returnedCategory
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.updateCategoryResponse(returnedCategory)))
    await store.receive(.delegate(.updateCategory(returnedCategory)))

    // 名前が変更されていなくてもUseCaseが呼び出されることを確認
    #expect(updatedCategoryFromUseCase.value?.name == "カテゴリ")
    await store.finish()
  }
}
