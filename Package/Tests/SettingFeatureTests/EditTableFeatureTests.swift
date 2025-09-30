//
//  EditTableFeatureTests.swift
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
struct EditTableFeatureTests {
  typealias Feature = EditTableFeature
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

  // MARK: - State初期化テスト

  @Test @MainActor
  func testStateInitialization_setsTableAndName() async {
    let table = createTable(name: "テストテーブル")
    let state = Feature.State(table: table)

    #expect(state.table == table)
    #expect(state.tableName == "テストテーブル")
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testHandleError_sendsErrorToHandler() async {
    let table = createTable()
    let error = AppError.unknown
    let errorInfo = error.toErrorInfo()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State(table: table)) {
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
    let table = createTable()
    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    }

    await store.send(.view(.onAppear))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_triggersSaveInternalAction() async {
    let table = createTable()
    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.save))
    await store.finish()
  }

  @Test @MainActor
  func testBackButtonTapped_callsDismiss() async {
    let table = createTable()
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State(table: table)) {
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

  @Test @MainActor
  func testDeleteButtonTapped_presentsAlert() async {
    let table = createTable()
    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    }

    await store.send(.view(.deleteButtonTapped)) {
      $0.alert = AlertState {
        TextState("テーブルを削除しますか？")
      } actions: {
        ButtonState(role: .destructive, action: .send(.confirmDelete)) {
          TextState("削除")
        }
        ButtonState(role: .cancel, action: .send(.cancel)) {
          TextState("キャンセル")
        }
      } message: {
        TextState("この操作は取り消せません。")
      }
    }
    await store.finish()
  }

  // MARK: - 内部アクション

  @Test @MainActor
  func testSave_withNameChange_callsUseCaseAndSendsDelegate() async {
    let originalTable = createTable(name: "オリジナル")
    let updatedName = "更新されたテーブル"
    let updatedTable = createTable(id: originalTable.id, name: updatedName)
    var dismissCalled = false
    let updatedTableFromUseCase = LockIsolated<(Table, String)?>(nil)

    var initialState = Feature.State(table: originalTable)
    initialState.tableName = updatedName

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.update = { table, newName in
        updatedTableFromUseCase.setValue((table, newName))
        #expect(table == originalTable)
        #expect(newName == updatedName)
        return updatedTable
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateTable(updatedTable)))

    let result = updatedTableFromUseCase.value
    #expect(result?.0 == originalTable)
    #expect(result?.1 == updatedName)
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withoutNameChange_onlyCallsDismiss() async {
    let table = createTable(name: "テーブル")
    var dismissCalled = false
    let useCaseWasCalled = LockIsolated<Bool>(false)

    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.update = { _, _ in
        useCaseWasCalled.setValue(true)
        return table
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))

    #expect(!useCaseWasCalled.value)
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_onFailure_reportsError() async {
    let table = createTable()
    let error = TableValidationError.invalidNameEmpty
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State(table: table)
    initialState.tableName = "更新されたテーブル"

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.update = { _, _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.save))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testDelete_callsUseCaseAndSendsDelegate() async {
    let table = createTable()
    var dismissCalled = false
    let deletedTable = LockIsolated<Table?>(nil)

    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.delete = { table in
        deletedTable.setValue(table)
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.delete))
    await store.receive(.delegate(.deleteTable(table)))

    #expect(deletedTable.value == table)
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testDelete_onFailure_reportsError() async {
    let table = createTable()
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.delete = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.delete))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesTableName() async {
    let table = createTable()
    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    }

    await store.send(.binding(.set(\.tableName, "新しいテーブル名"))) {
      $0.tableName = "新しいテーブル名"
    }
    await store.finish()
  }

  // MARK: - Alertアクション

  @Test @MainActor
  func testAlertConfirmDelete_triggersDeleteInternalAction() async {
    let table = createTable()
    var initialState = Feature.State(table: table)
    initialState.alert = AlertState { TextState("削除確認") }

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.tableUseCase.delete = { _ in }
    }

    await store.send(.alert(.presented(.confirmDelete))) {
      $0.alert = nil
    }
    await store.receive(.internal(.delete))
    await store.receive(.delegate(.deleteTable(table)))
    await store.finish()
  }

  @Test @MainActor
  func testAlertCancel_doesNothing() async {
    let table = createTable()
    var initialState = Feature.State(table: table)
    initialState.alert = AlertState { TextState("削除確認") }

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.alert(.presented(.cancel))) {
      $0.alert = nil
    }
    await store.finish()
  }

  @Test @MainActor
  func testAlertDismiss_doesNothing() async {
    let table = createTable()
    var initialState = Feature.State(table: table)
    initialState.alert = AlertState { TextState("削除確認") }

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.alert(.dismiss)) {
      $0.alert = nil
    }
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let table = createTable()
    let updatedTable = createTable(id: table.id, name: "更新済み")

    let store = TestStore(initialState: Feature.State(table: table)) {
      Feature()
    }

    await store.send(.delegate(.updateTable(updatedTable)))
    await store.send(.delegate(.deleteTable(table)))
    await store.finish()
  }
}
