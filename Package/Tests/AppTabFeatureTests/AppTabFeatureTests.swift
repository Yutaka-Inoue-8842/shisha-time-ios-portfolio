//
//  AppTabFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/30.
//

import CharcoalTimerFeature
import Common
import ComposableArchitecture
import DocumentFeature
import Domain
import Foundation
import Testing

@testable import AppTabFeature

@MainActor
struct AppTabFeatureTests {
  typealias Feature = AppTabFeature
  typealias Category = Domain.Category

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
  func testHamburgerMenuTapped_togglesSidebar() async {
    var initialState = Feature.State()
    initialState.sidebar.isPresented = false

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.hamburgerMenuTapped)) {
      $0.sidebar.isPresented = true
    }
    await store.finish()
  }

  @Test @MainActor
  func testHamburgerMenuTapped_togglesSidebarWhenAlreadyPresented() async {
    var initialState = Feature.State()
    initialState.sidebar.isPresented = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.hamburgerMenuTapped)) {
      $0.sidebar.isPresented = false
    }
    await store.finish()
  }

  // MARK: - Internalアクション

  @Test @MainActor
  func testInternal_doesNothing() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    // Internalアクションは空のため、特にテストすることがない
    await store.finish()
  }

  // MARK: - CharcoalTimerアクション

  @Test @MainActor
  func testCharcoalTimerAction_passesThrough() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: [], nextToken: nil)
      }
    }

    // CharcoalTimerアクションはそのまま通される
    await store.send(.charcoalTimer(.view(.onAppear)))
    await store.receive(.charcoalTimer(.internal(.fetchTimer)))
    await store.receive(.charcoalTimer(.internal(.startTimer)))
    await store.receive(.charcoalTimer(.internal(.fetchTimerResponse([])))) {
      $0.charcoalTimer.isTimerUpdate.toggle()
    }
    await store.receive(.charcoalTimer(.internal(.timerTick))) {
      $0.charcoalTimer.isTimerUpdate.toggle()
    }

    await store.send(.charcoalTimer(.internal(.stopTimer)))
    await store.finish()
  }

  // MARK: - DocumentListアクション

  @Test @MainActor
  func testDocumentListHamburgerMenuTapped_togglesSidebar() async {
    var initialState = Feature.State()
    initialState.sidebar.isPresented = false

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.documentList(.delegate(.hamburgerMenuTapped))) {
      $0.sidebar.isPresented = true
    }
    await store.finish()
  }

  @Test @MainActor
  func testDocumentListOtherActions_passThrough() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetch = { limit in
        return .init(items: [], nextToken: nil)
      }
    }

    // 他のDocumentListアクションはそのまま通される
    await store.send(.documentList(.view(.onAppear)))
    await store.receive(.documentList(.internal(.fetchDocument)))
    await store.receive(.documentList(.internal(.fetchDocumentResponse([], nil)))) {
      $0.documentList.isLoaded = true
      $0.documentList.documentList = []
      $0.documentList.nextToken = nil
    }
    await store.finish()
  }

  // MARK: - Sidebarアクション

  @Test @MainActor
  func testSidebarDismiss_hidesSidebar() async {
    var initialState = Feature.State()
    initialState.sidebar.isPresented = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.sidebar(.delegate(.dismiss))) {
      $0.sidebar.isPresented = false
    }
    await store.finish()
  }

  @Test @MainActor
  func testSidebarSelectCategory_sendsToDocumentList() async {
    let mockCategory = Category(
      id: "test-category",
      name: "テストカテゴリ",
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetchByCategory = { mockCategory, limit in
        return .init(items: [], nextToken: nil)
      }
    }

    await store.send(.sidebar(.delegate(.selectCategory(mockCategory))))
    await store.receive(.documentList(.view(.categorySelected(mockCategory)))) {
      $0.sidebar.isPresented = false
      $0.documentList.selectedCategory = mockCategory
      $0.documentList.documentList = []
      $0.documentList.nextToken = nil
    }
    await store.receive(.documentList(.internal(.fetchDocumentResponse([], nil)))) {
      $0.documentList.isLoaded = true
    }

    await store.finish()
  }

  @Test @MainActor
  func testSidebarOtherActions_passThrough() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.categoryUseCase.fetch = { limit in
        return .init(items: [], nextToken: nil)
      }
    }

    // 他のSidebarアクションはそのまま通される
    await store.send(.sidebar(.view(.onAppear))) {
      $0.sidebar.isLoaded = true
    }
    await store.receive(.sidebar(.internal(.fetchCategories)))
    await store.receive(.sidebar(.internal(.fetchCategoriesResponse([], nextToken: nil))))
    await store.finish()
  }

  // MARK: - 統合テスト

  @Test @MainActor
  func testIntegration_hamburgerMenuWorkflow() async {
    var initialState = Feature.State()
    initialState.sidebar.isPresented = false

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    // ハンバーガーメニューを開く
    await store.send(.view(.hamburgerMenuTapped)) {
      $0.sidebar.isPresented = true
    }

    // サイドバーを閉じる
    await store.send(.sidebar(.delegate(.dismiss))) {
      $0.sidebar.isPresented = false
    }

    await store.finish()
  }

  @Test @MainActor
  func testIntegration_categorySelectionWorkflow() async {
    let mockCategory = Category(
      id: "test-category",
      name: "テストカテゴリ",
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )

    var initialState = Feature.State()
    initialState.sidebar.isPresented = false

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetchByCategory = { mockCategory, limit in
        return .init(items: [], nextToken: nil)
      }
    }

    // DocumentListからハンバーガーメニューを開く
    await store.send(.documentList(.delegate(.hamburgerMenuTapped))) {
      $0.sidebar.isPresented = true
    }

    // カテゴリを選択
    await store.send(.sidebar(.view(.categoryTapped(mockCategory)))) {
      $0.sidebar.selectedCategory = mockCategory
      $0.sidebar.isPresented = false
    }

    await store.receive(.sidebar(.delegate(.dismiss)))
    await store.receive(.sidebar(.delegate(.selectCategory(mockCategory))))

    await store.receive(.documentList(.view(.categorySelected(mockCategory)))) {
      $0.documentList.selectedCategory = mockCategory
      $0.documentList.documentList = []
      $0.documentList.nextToken = nil
    }
    await store.receive(.documentList(.internal(.fetchDocumentResponse([], nil)))) {
      $0.documentList.isLoaded = true
    }

    await store.finish()
  }

  // MARK: - 状態の境界値テスト

  @Test @MainActor
  func testInitialState() async {
    let state = Feature.State()

    // 初期状態の検証
    #expect(state.sidebar.isPresented == false)

    let store = TestStore(initialState: state) {
      Feature()
    }

    await store.finish()
  }

  @Test @MainActor
  func testMultipleHamburgerMenuTaps() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    // 複数回ハンバーガーメニューをタップしてトグル動作を確認
    await store.send(.view(.hamburgerMenuTapped)) {
      $0.sidebar.isPresented = true
    }

    await store.send(.view(.hamburgerMenuTapped)) {
      $0.sidebar.isPresented = false
    }

    await store.send(.view(.hamburgerMenuTapped)) {
      $0.sidebar.isPresented = true
    }

    await store.finish()
  }

  // MARK: - Scope機能のテスト

  @Test @MainActor
  func testCharcoalTimerScopeIntegration() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        return .init(items: [], nextToken: nil)
      }
    }

    // CharcoalTimerFeatureのアクションが適切にスコープされることを確認
    await store.send(.charcoalTimer(.view(.onAppear)))

    // CharcoalTimerの内部アクションも通ることを確認
    await store.receive(.charcoalTimer(.internal(.fetchTimer)))
    await store.receive(.charcoalTimer(.internal(.startTimer)))
    await store.receive(.charcoalTimer(.internal(.fetchTimerResponse([])))) {
      $0.charcoalTimer.isTimerUpdate.toggle()
    }
    await store.receive(.charcoalTimer(.internal(.timerTick))) {
      $0.charcoalTimer.isTimerUpdate.toggle()
    }

    await store.send(.charcoalTimer(.internal(.stopTimer)))

    await store.finish()
  }

  @Test @MainActor
  func testDocumentListScopeIntegration() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.documentUseCase.fetch = { limit in
        return .init(items: [], nextToken: nil)
      }
    }

    // DocumentListFeatureのアクションが適切にスコープされることを確認
    await store.send(.documentList(.view(.onAppear)))
    await store.receive(.documentList(.internal(.fetchDocument)))
    await store.receive(.documentList(.internal(.fetchDocumentResponse([], nil)))) {
      $0.documentList.isLoaded = true
      $0.documentList.documentList = []
      $0.documentList.nextToken = nil
    }

    await store.finish()
  }

}
