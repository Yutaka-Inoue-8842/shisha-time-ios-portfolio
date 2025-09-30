//
//  SettingMenuFeatureTests.swift
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
struct SettingMenuFeatureTests {
  typealias Feature = SettingMenuFeature

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
  func testTableButtonTapped_presentsTableListScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.tableButtonTapped)) {
      $0.destination = .tableList(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testTimeIntervalButtonTapped_presentsTimeIntervalScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.timeIntervalButtonTapped)) {
      $0.destination = .timeIntervalSetting(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testTemplateButtonTapped_presentsTemplateListScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.templateButtonTapped)) {
      $0.destination = .templateList(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testCategoryButtonTapped_presentsCategoryListScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.categoryButtonTapped)) {
      $0.destination = .categoryList(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testBackButtonTapped_callsDismiss() async {
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.backButtonTapped))

    #expect(dismissCalled)
    await store.finish()
  }

  // MARK: - 内部アクション（現在は空）

  @Test @MainActor
  func testInternalAction_empty() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    // InternalActionは現在空なので、この段階では特にテストするものがない
    // 将来的に内部アクションが追加された場合にはここにテストを追加

    await store.finish()
  }

  // MARK: - 複数のナビゲーションテスト

  @Test @MainActor
  func testMultipleNavigations_eachOverwritesDestination() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    // 最初のナビゲーション
    await store.send(.view(.tableButtonTapped)) {
      $0.destination = .tableList(.init())
    }

    // 別のナビゲーション（前のdestinationを上書き）
    await store.send(.view(.templateButtonTapped)) {
      $0.destination = .templateList(.init())
    }

    // さらに別のナビゲーション
    await store.send(.view(.categoryButtonTapped)) {
      $0.destination = .categoryList(.init())
    }

    await store.finish()
  }

  // MARK: - State初期化テスト

  @Test @MainActor
  func testStateInitialization() async {
    let state = Feature.State()

    #expect(state.destination == nil)
  }
}
