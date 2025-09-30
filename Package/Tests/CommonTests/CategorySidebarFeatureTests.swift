//
//  CategorySidebarFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/31.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import Testing

@testable import Common

@MainActor
struct CategorySidebarFeatureTests {
  typealias Feature = CategorySidebarFeature
  typealias Category = Domain.Category

  // MARK: - Mock Categories

  func makeMockCategory(id: String, name: String) -> Category {
    Category(
      id: id,
      name: name,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  var mockCategory1: Category { makeMockCategory(id: "category-1", name: "カテゴリ1") }
  var mockCategory2: Category { makeMockCategory(id: "category-2", name: "カテゴリ2") }
  var mockCategories: [Category] { [mockCategory1, mockCategory2] }

  // MARK: - Viewアクション

  @Test @MainActor
  func testBackgroundTapped_dismissesSidebar() async {
    var initialState = Feature.State()
    initialState.isPresented = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.backgroundTapped)) {
      $0.isPresented = false
    }
    await store.receive(.delegate(.dismiss))
    await store.finish()
  }

  @Test @MainActor
  func testCloseButtonTapped_dismissesSidebar() async {
    var initialState = Feature.State()
    initialState.isPresented = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.closeButtonTapped)) {
      $0.isPresented = false
    }
    await store.receive(.delegate(.dismiss))
    await store.finish()
  }

  @Test @MainActor
  func testCategoryTapped_selectsCategoryAndDismisses() async {
    let mockCategory1 = mockCategory1
    let mockCategory2 = mockCategory2
    var initialState = Feature.State()
    initialState.isPresented = true
    initialState.categoryList = [mockCategory1, mockCategory2]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.categoryTapped(mockCategory1))) {
      $0.selectedCategory = mockCategory1
      $0.isPresented = false
    }
    await store.receive(.delegate(.dismiss))
    await store.receive(.delegate(.selectCategory(mockCategory1)))
    await store.finish()
  }

  @Test @MainActor
  func testCategoryTappedWithNil_selectsNilAndDismisses() async {
    var initialState = Feature.State()
    initialState.isPresented = true
    initialState.selectedCategory = mockCategory1

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.categoryTapped(nil))) {
      $0.selectedCategory = nil
      $0.isPresented = false
    }
    await store.receive(.delegate(.dismiss))
    await store.receive(.delegate(.selectCategory(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_fetchesCategoriesWhenNotLoaded() async {
    let mockCategories = mockCategories
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: mockCategories, nextToken: "next-token")
      }
    }

    await store.send(.view(.onAppear)) {
      $0.isLoaded = true
    }
    await store.receive(.internal(.fetchCategories))
    await store.receive(.internal(.fetchCategoriesResponse(mockCategories, nextToken: "next-token"))) {
      $0.categoryList = mockCategories
      $0.nextToken = "next-token"
    }
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_doesNothingWhenAlreadyLoaded() async {
    var initialState = Feature.State()
    initialState.isLoaded = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.onAppear))
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_loadsMoreCategoriesWhenHasNextToken() async {
    var initialState = Feature.State()
    initialState.nextToken = "next-token"
    initialState.categoryList = [mockCategory1]

    let additionalCategories = [mockCategory2]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchMore = { nextToken, limit in
        #expect(nextToken == "next-token")
        #expect(limit == 20)
        return .init(items: additionalCategories, nextToken: nil)
      }
    }

    await store.send(.view(.loadMore)) {
      $0.isLoadingMore = true
    }
    await store.receive(.internal(.fetchMoreCategories))
    await store.receive(.internal(.fetchMoreCategoriesResponse(additionalCategories, nextToken: nil))) {
      $0.categoryList.append(contentsOf: additionalCategories)
      $0.nextToken = nil
      $0.isLoadingMore = false
    }
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_doesNothingWhenNoNextToken() async {
    var initialState = Feature.State()
    initialState.nextToken = nil
    initialState.isLoadingMore = false

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.loadMore))
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_doesNothingWhenAlreadyLoading() async {
    var initialState = Feature.State()
    initialState.nextToken = "next-token"
    initialState.isLoadingMore = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.loadMore))
    await store.finish()
  }

  // MARK: - Internalアクション

  @Test @MainActor
  func testFetchCategories_success() async {
    let mockCategories = mockCategories
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        return .init(items: mockCategories, nextToken: "next-token")
      }
    }

    await store.send(.internal(.fetchCategories))
    await store.receive(.internal(.fetchCategoriesResponse(mockCategories, nextToken: "next-token"))) {
      $0.categoryList = mockCategories
      $0.nextToken = "next-token"
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchCategories_failure() async {
    let mockError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        throw mockError
      }
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { AsyncStream { _ in } }
      )
    }

    await store.send(.internal(.fetchCategories))
    await store.receive(.internal(.handleError(mockError.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testFetchCategoriesResponse_setsState() async {
    let mockCategories = mockCategories
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchCategoriesResponse(mockCategories, nextToken: "next-token"))) {
      $0.categoryList = mockCategories
      $0.nextToken = "next-token"
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreCategories_success() async {
    var initialState = Feature.State()
    initialState.nextToken = "next-token"

    let additionalCategories = [mockCategory2]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchMore = { nextToken, limit in
        return .init(items: additionalCategories, nextToken: nil)
      }
    }

    await store.send(.internal(.fetchMoreCategories))
    await store.receive(.internal(.fetchMoreCategoriesResponse(additionalCategories, nextToken: nil))) {
      $0.categoryList.append(contentsOf: additionalCategories)
      $0.nextToken = nil
      $0.isLoadingMore = false
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreCategories_noNextToken() async {
    var initialState = Feature.State()
    initialState.nextToken = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.fetchMoreCategories))
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreCategories_failure() async {
    var initialState = Feature.State()
    initialState.nextToken = "next-token"

    let mockError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch more error"])

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchMore = { nextToken, limit in
        throw mockError
      }
      $0.errorHandler = ErrorHandler(
        send: { _ in },
        stream: { AsyncStream { _ in } }
      )
    }

    await store.send(.internal(.fetchMoreCategories))
    await store.receive(.internal(.handleError(mockError.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testHandleError_sendsToErrorHandler() async {
    let mockErrorInfo = ErrorInfo(
      title: "エラータイトル",
      message: "エラーメッセージ",
      buttonText: "OK"
    )

    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.handleError(mockErrorInfo)))

    #expect(sentErrorInfo.value == mockErrorInfo)
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegateAction_doesNothing() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.delegate(.dismiss))
    await store.send(.delegate(.selectCategory(mockCategory1)))
    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_isPresented() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.binding(.set(\.isPresented, true))) {
      $0.isPresented = true
    }

    await store.send(.binding(.set(\.isPresented, false))) {
      $0.isPresented = false
    }

    await store.finish()
  }

  @Test @MainActor
  func testBinding_selectedCategory() async {
    let mockCategory1 = mockCategory1
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.binding(.set(\.selectedCategory, mockCategory1))) {
      $0.selectedCategory = mockCategory1
    }

    await store.send(.binding(.set(\.selectedCategory, nil))) {
      $0.selectedCategory = nil
    }

    await store.finish()
  }

  // MARK: - 統合テスト

  @Test @MainActor
  func testIntegration_fetchAndSelectCategory() async {
    let mockCategory1 = mockCategory1
    let mockCategory2 = mockCategory2
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        return .init(items: [mockCategory1, mockCategory2], nextToken: nil)
      }
    }

    // 初期読み込み
    await store.send(.view(.onAppear)) {
      $0.isLoaded = true
    }
    await store.receive(.internal(.fetchCategories))
    await store.receive(.internal(.fetchCategoriesResponse([mockCategory1, mockCategory2], nextToken: nil))) {
      $0.categoryList = [mockCategory1, mockCategory2]
      $0.nextToken = nil
    }

    // カテゴリ選択
    await store.send(.view(.categoryTapped(mockCategory1))) {
      $0.selectedCategory = mockCategory1
      $0.isPresented = false
    }
    await store.receive(.delegate(.dismiss))
    await store.receive(.delegate(.selectCategory(mockCategory1)))

    await store.finish()
  }

  @Test @MainActor
  func testIntegration_paginationFlow() async {
    let mockCategory1 = mockCategory1
    let mockCategory2 = mockCategory2
    var initialState = Feature.State()
    initialState.isLoaded = true
    initialState.categoryList = [mockCategory1]
    initialState.nextToken = "next-token"

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchMore = { nextToken, limit in
        return .init(items: [mockCategory2], nextToken: nil)
      }
    }

    // さらに読み込み
    await store.send(.view(.loadMore)) {
      $0.isLoadingMore = true
    }
    await store.receive(.internal(.fetchMoreCategories))
    await store.receive(.internal(.fetchMoreCategoriesResponse([mockCategory2], nextToken: nil))) {
      $0.categoryList.append(contentsOf: [mockCategory2])
      $0.nextToken = nil
      $0.isLoadingMore = false
    }

    // 次のページがないので何もしない
    await store.send(.view(.loadMore))

    await store.finish()
  }

  // MARK: - 状態の境界値テスト

  @Test @MainActor
  func testInitialState() async {
    let state = Feature.State()

    // 初期状態の検証
    #expect(state.isPresented == false)
    #expect(state.categoryList.isEmpty)
    #expect(state.selectedCategory == nil)
    #expect(state.nextToken == nil)
    #expect(state.isLoadingMore == false)
    #expect(state.isLoaded == false)

    let store = TestStore(initialState: state) {
      Feature()
    }

    await store.finish()
  }

  @Test @MainActor
  func testCustomInitialState() async {
    let state = Feature.State(
      isPresented: true,
      categoryList: mockCategories,
      selectedCategory: mockCategory1
    )

    #expect(state.isPresented == true)
    #expect(state.categoryList == mockCategories)
    #expect(state.selectedCategory == mockCategory1)

    let store = TestStore(initialState: state) {
      Feature()
    }

    await store.finish()
  }

  @Test @MainActor
  func testMultipleLoadMoreRequests() async {
    let mockCategory2 = mockCategory2
    var initialState = Feature.State()
    initialState.nextToken = "next-token"
    initialState.isLoadingMore = true

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchMore = { nextToken, limit in
        return .init(items: [mockCategory2], nextToken: nil)
      }
    }

    // 読み込み中なので無視される
    await store.send(.view(.loadMore))

    await store.finish()
  }

  // MARK: - エラーハンドリングのテスト

  @Test @MainActor
  func testErrorHandling_fetchCategoriesError() async {
    let mockError = NSError(domain: "network", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Network error"])

    let sentErrorInfo = LockIsolated<[ErrorInfo]>([])

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        throw mockError
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.withValue { $0.append(errorInfo) }
      }
    }

    await store.send(.internal(.fetchCategories))
    await store.receive(.internal(.handleError(mockError.toErrorInfo())))

    #expect(sentErrorInfo.value.count == 1)
    #expect(sentErrorInfo.value.first?.title == mockError.toErrorInfo().title)

    await store.finish()
  }

  @Test @MainActor
  func testErrorHandling_fetchMoreCategoriesError() async {
    var initialState = Feature.State()
    initialState.nextToken = "next-token"

    let mockError = NSError(domain: "server", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])

    let sentErrorInfo = LockIsolated<[ErrorInfo]>([])

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetchMore = { nextToken, limit in
        throw mockError
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.withValue { $0.append(errorInfo) }
      }
    }

    await store.send(.internal(.fetchMoreCategories))
    await store.receive(.internal(.handleError(mockError.toErrorInfo())))

    #expect(sentErrorInfo.value.count == 1)
    #expect(sentErrorInfo.value.first?.message == mockError.toErrorInfo().message)

    await store.finish()
  }

  // MARK: - パフォーマンステスト

  @Test @MainActor
  func testLargeCategoryList() async {
    let largeCategoryList = (1...100).map { index in
      makeMockCategory(id: "category-\(index)", name: "カテゴリ\(index)")
    }

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchCategoriesResponse(largeCategoryList, nextToken: nil))) {
      $0.categoryList = largeCategoryList
      $0.nextToken = nil
    }

    #expect(store.state.categoryList.count == 100)
    await store.finish()
  }
}
