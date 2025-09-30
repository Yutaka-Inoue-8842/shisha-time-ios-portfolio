//
//  AddTableFeatureTests.swift
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
struct AddTableFeatureTests {
  typealias Feature = AddTableFeature
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
  func testAddTable_callsUseCaseAndSendsDelegate() async {
    let tableName = "新しいテーブル"
    let createdTable = createTable(name: tableName)
    var dismissCalled = false
    let tableFromUseCase = LockIsolated<String?>(nil)

    var initialState = Feature.State()
    initialState.tableName = tableName

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.create = { name in
        tableFromUseCase.setValue(name)
        #expect(name == tableName)
        return createdTable
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.addTable))
    await store.receive(.delegate(.addTable(createdTable)))

    #expect(tableFromUseCase.value == tableName)
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testAddTable_onFailure_reportsError() async {
    let error = TableValidationError.invalidNameEmpty
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State()
    initialState.tableName = "テーブル名"

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.create = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.addTable))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesTableName() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.binding(.set(\.tableName, "新しいテーブル名"))) {
      $0.tableName = "新しいテーブル名"
    }
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let table = createTable()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.delegate(.addTable(table)))
    await store.finish()
  }

  // MARK: - バリデーションエラーのテスト

  @Test @MainActor
  func testAddTable_withEmptyName_reportsValidationError() async {
    let error = TableValidationError.invalidNameEmpty
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State()
    initialState.tableName = ""  // 空文字でバリデーションエラー

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.create = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.addTable))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testAddTable_withLongName_reportsValidationError() async {
    let longName = String(repeating: "a", count: 30)  // 20文字超過
    let error = TableValidationError.invalidNameLength
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State()
    initialState.tableName = longName

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.create = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.addTable))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }
}
