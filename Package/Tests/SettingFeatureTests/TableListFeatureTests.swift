//
//  TableListFeatureTests.swift
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
struct TableListFeatureTests {
  typealias Feature = TableListFeature
  typealias Table = Domain.Table

  // MARK: - Mock Data Creation

  private func createTable(id: String = UUID().uuidString, name: String = "テーブル") -> Table {
    Table(
      id: id,
      name: name,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testFetchAllTableResponse_setsList() async {
    let tables = [
      createTable(),
      createTable()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchAllTableResponse(tables))) {
      $0.tableList = tables
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddTable_insertsAtTop() async {
    let table = createTable()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.addTable(table))) {
      $0.tableList = [table]
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddTable_insertsAtTopOfExistingList() async {
    let existingTable = createTable(name: "既存テーブル")
    let newTable = createTable(name: "新しいテーブル")

    var initialState = Feature.State()
    initialState.tableList = [existingTable]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.addTable(newTable))) {
      $0.tableList = [newTable, existingTable]
    }
    await store.finish()
  }

  @Test @MainActor
  func testUpdateTable_replacesMatchedItem() async {
    let id = UUID().uuidString
    let beforeTable = createTable(id: id, name: "Before")
    let afterTable = createTable(id: id, name: "After")
    var initialState = Feature.State()
    initialState.tableList = [beforeTable]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateTable(afterTable))) {
      $0.tableList = [afterTable]
    }
    await store.finish()
  }

  @Test @MainActor
  func testRemoveTable_removesMatchedItem() async {
    let tables = [
      createTable(),
      createTable()
    ]
    var initialState = Feature.State()
    initialState.tableList = tables

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.removeTable(tables[0]))) {
      $0.tableList = [tables[1]]
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

  // MARK: - Viewアクション（ナビゲーション）

  @Test @MainActor
  func testOnAppear_fetchesAllAndSetsList() async {
    let tables = [
      createTable(),
      createTable()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.fetchAll = {
        tables
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchAllTableResponse(tables))) {
      $0.tableList = tables
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
      $0.tableUseCase.fetchAll = {
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testAddButtonTapped_presentsAddScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addTable(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testEditTableTapped_presentsEditScreenWithTable() async {
    let table = createTable()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.editTableTapped(table))) {
      $0.destination = .editTable(.init(table: table))
    }
    await store.finish()
  }

  // MARK: - 子画面 delegate → 親のinternalに変換されること

  @Test @MainActor
  func testAddTableDelegate_flowsToInternalAdd() async {
    let table = createTable()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    // まず destination を設定
    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addTable(.init())
    }

    // その後で delegate アクションを送信
    await store.send(.destination(.presented(.addTable(.delegate(.addTable(table))))))
    await store.receive(.internal(.addTable(table))) {
      $0.tableList = [table]
    }
    await store.finish()
  }

  @Test @MainActor
  func testEditTableDelegate_flowsToInternalUpdate() async {
    let id = UUID().uuidString
    let beforeTable = createTable(id: id, name: "Before")
    let afterTable = createTable(id: id, name: "After")
    var initialState = Feature.State()
    initialState.tableList = [beforeTable]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.editTableTapped(beforeTable))) {
      $0.destination = .editTable(.init(table: beforeTable))
    }

    await store.send(.destination(.presented(.editTable(.delegate(.updateTable(afterTable))))))
    await store.receive(.internal(.updateTable(afterTable))) {
      $0.tableList = [afterTable]
    }
    await store.finish()
  }

  @Test @MainActor
  func testEditTableDelegate_deleteTable_flowsToInternalRemove() async {
    let table = createTable()
    var initialState = Feature.State()
    initialState.tableList = [table]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.editTableTapped(table))) {
      $0.destination = .editTable(.init(table: table))
    }

    await store.send(.destination(.presented(.editTable(.delegate(.deleteTable(table))))))
    await store.receive(.internal(.removeTable(table))) {
      $0.tableList = []
    }
    await store.finish()
  }

  // MARK: - エッジケース

  @Test @MainActor
  func testUpdateTable_whenItemNotFound_keepsOriginalState() async {
    let tables = [
      createTable(),
      createTable()
    ]
    var initialState = Feature.State()
    initialState.tableList = [tables[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateTable(tables[1])))
    await store.finish()
  }

  @Test @MainActor
  func testRemoveTable_whenItemNotFound_keepsOriginalState() async {
    let tables = [
      createTable(),
      createTable()
    ]
    var initialState = Feature.State()
    initialState.tableList = [tables[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.removeTable(tables[1])))
    await store.finish()
  }
}
