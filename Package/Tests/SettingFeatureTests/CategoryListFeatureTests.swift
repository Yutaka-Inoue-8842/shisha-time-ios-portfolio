//
//  CategoryListFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/11.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import Testing

@testable import SettingFeature

@MainActor
struct CategoryListFeatureTests {
  typealias Feature = CategoryListFeature
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
  func testFetchAllCategoryResponse_setsList() async {
    let categories = [
      createCategory(),
      createCategory()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchAllCategoryResponse(categories))) {
      $0.categoryList = categories
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddCategory_appends() async {
    let category = createCategory()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.addCategory(category))) {
      $0.categoryList = [category]
    }
    await store.finish()
  }

  @Test @MainActor
  func testUpdateCategory_replacesMatchedItem() async {
    let id = UUID().uuidString
    let beforeCategory = createCategory(id: id, name: "Before")
    let afterCategory = createCategory(id: id, name: "After")
    var initialState = Feature.State()
    initialState.categoryList = [beforeCategory]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateCategory(afterCategory))) {
      $0.categoryList = [afterCategory]
    }
    await store.finish()
  }

  @Test @MainActor
  func testDeleteCategory_removesMatchedItem() async {
    let categories = [
      createCategory(),
      createCategory()
    ]
    var initialState = Feature.State()
    initialState.categoryList = categories

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteCategory(categories[0]))) {
      $0.categoryList = [categories[1]]
    }
    await store.finish()
  }

  // MARK: - Viewアクション（ナビゲーション）

  @Test @MainActor
  func testAddButtonTapped_presentsAddScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addCategory(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testEditCategoryTapped_presentsEditScreenWithCategory() async {
    let category = createCategory()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.editCategoryTapped(category))) {
      $0.destination = .editCategory(.init(category: category))
    }
    await store.finish()
  }

  // MARK: - 子画面 delegate → 親のinternalに変換されること
  @Test @MainActor
  func testAddCategoryDelegate_flowsToInternalAdd() async {
    let category = createCategory()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    // まず destination を設定
    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addCategory(.init())
    }

    // その後で delegate アクションを送信
    await store.send(.destination(.presented(.addCategory(.delegate(.addCategory(category))))))
    await store.receive(.internal(.addCategory(category))) {
      $0.categoryList = [category]
    }
    await store.finish()
  }

  @Test @MainActor
  func testEditCategoryDelegate_flowsToInternalUpdate() async {
    let id = UUID().uuidString
    let beforeCategory = createCategory(id: id, name: "Before")
    let afterCategory = createCategory(id: id, name: "After")
    var initialState = Feature.State()
    initialState.categoryList = [beforeCategory]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.editCategoryTapped(beforeCategory))) {
      $0.destination = .editCategory(.init(category: beforeCategory))
    }

    await store.send(.destination(.presented(.editCategory(.delegate(.updateCategory(afterCategory))))))
    await store.receive(.internal(.updateCategory(afterCategory))) {
      $0.categoryList = [afterCategory]
    }
    await store.finish()
  }

  // MARK: - 副作用：スワイプ削除成功/失敗

  @Test @MainActor
  func testSwipeToDelete_callsUseCaseAndRemovesOnSuccess() async {
    let category = createCategory()
    let deletedCategory = LockIsolated<Category?>(nil)
    var initialState = Feature.State()
    initialState.categoryList = [category]

    let store = TestStore(
      initialState: initialState
    ) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.delete = { category in
        deletedCategory.setValue(category)
      }
    }

    await store.send(.view(.swipeToDelete(category)))
    await store.receive(.internal(.deleteCategory(category))) {
      $0.categoryList = []
    }

    #expect(deletedCategory.value == category)
    await store.finish()
  }

  @Test @MainActor
  func testSwipeToDelete_onFailure_reportsErrorAndKeepsState() async {
    let error = AppError.unknown
    let category = createCategory()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)
    var initialState = Feature.State()
    initialState.categoryList = [category]

    let store = TestStore(
      initialState: initialState
    ) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.delete = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.swipeToDelete(category)))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(store.state.categoryList == [category])
    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  // MARK: - onAppear（fetchAll）: 戻り型に合わせて有効化

  @Test @MainActor
  func testOnAppear_fetchesAllAndSetsList() async {
    let categories = [
      createCategory(),
      createCategory()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchAll = {
        .init(items: categories, nextToken: "nextToken")
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchAllCategoryResponse(categories))) {
      $0.categoryList = categories
    }
  }

  @Test @MainActor
  func testOnAppear_onFailure_reportsErrorAndKeepsEmptyState() async {
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchAll = {
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.onAppear))

    // handleErrorアクションが送信されることを確認
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(store.state.categoryList.isEmpty)
    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testUpdateCategory_whenItemNotFound_keepsOriginalState() async {
    let categories = [
      createCategory(),
      createCategory()
    ]
    var initialState = Feature.State()
    initialState.categoryList = [categories[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateCategory(categories[1])))
    await store.finish()
  }

  @Test @MainActor
  func testDeleteCategory_whenItemNotFound_keepsOriginalState() async {
    let categories = [
      createCategory(),
      createCategory()
    ]
    var initialState = Feature.State()
    initialState.categoryList = [categories[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteCategory(categories[1])))
    await store.finish()
  }
}
