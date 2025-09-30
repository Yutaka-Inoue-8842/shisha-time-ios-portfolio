//
//  EditCharcoalTimerFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/30.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import Testing

@testable import CharcoalTimerFeature

@MainActor
struct EditCharcoalTimerFeatureTests {
  typealias Feature = EditCharcoalTimerFeature
  typealias Timer = Feature.Timer
  typealias Table = Domain.Table
  typealias TimeInterval = Domain.TimeIntervalData

  // MARK: - Mock Data Creation

  private func createTimer(
    id: String = UUID().uuidString,
    name: String = "テストタイマー",
    minutesInterval: Int = 10
  ) -> Timer {
    Timer(
      id: id,
      nextCheckTime: .init(Date()),
      minutesInterval: minutesInterval,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  private func createTable(
    id: String = UUID().uuidString,
    name: String = "テーブル1",
  ) -> Table {
    Table(
      id: id,
      name: name,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  private func createTimeInterval(timeInterval: String = "") -> TimeInterval {
    TimeInterval(
      id: UUID(),
      timeInterval: timeInterval
    )
  }

  // MARK: - 初期化テスト

  @Test @MainActor
  func testInitialState_setsTimerAndInterval() async {
    let timer = createTimer(minutesInterval: 15)
    let state = Feature.State(timer: timer)

    #expect(state.timer == timer)
    #expect(state.selectedMinutesInterval == 15)
    #expect(state.selectedTable == nil)
    #expect(state.tables.isEmpty)
    #expect(state.minutesIntervals.isEmpty)
  }

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_fetchesTablesAndTimeIntervals() async {
    let timer = createTimer()
    let tables = [createTable()]
    let timeIntervals = [
      createTimeInterval(timeInterval: "10"),
      createTimeInterval(timeInterval: "15")
    ]

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    } withDependencies: {
      $0.timeIntervalUseCase.fetch = {
        return timeIntervals
      }
      $0.tableUseCase.fetchAll = {
        return tables
      }
    }

    await store.send(.view(.onAppear)) {
      $0.minutesIntervals = timeIntervals.compactMap { Int($0.timeInterval) }
    }
    await store.receive(.internal(.fetchAllTableResponse(tables))) {
      $0.tables = tables
    }
    await store.receive(.internal(.setCurrentTable(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_tablesFetchFailure_handlesError() async {
    let timer = createTimer()
    let error = AppError.unknown
    let timeIntervals = [createTimeInterval()]

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    } withDependencies: {
      $0.timeIntervalUseCase.fetch = {
        return timeIntervals
      }
      $0.tableUseCase.fetchAll = {
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_triggersSave() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.update = { _, _, _ in
        return timer
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.save))
    await store.receive(.delegate(.updateTimer(timer)))
    await store.finish()
  }

  // MARK: - Internalアクション

  @Test @MainActor
  func testFetchAllTableResponse_updatesTablesAndFetchesCurrentTable() async {
    let timer = createTimer()
    let tables = [createTable(), createTable(name: "テーブル2")]

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    }

    await store.send(.internal(.fetchAllTableResponse(tables))) {
      $0.tables = tables
    }
    await store.receive(.internal(.setCurrentTable(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testSetCurrentTable_updatesSelectedTable() async {
    let timer = createTimer()
    let table = createTable()

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    }

    await store.send(.internal(.setCurrentTable(table))) {
      $0.selectedTable = table
    }
    await store.finish()
  }

  @Test @MainActor
  func testSetCurrentTable_withNil_setsNil() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    }

    await store.send(.internal(.setCurrentTable(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testSave_updatesTimerAndDismisses() async {
    let originalTimer = createTimer(minutesInterval: 10)
    let updatedTimer = createTimer(id: originalTimer.id, minutesInterval: 15)
    let table = createTable()
    var dismissCalled = false

    var initialState = Feature.State(timer: originalTimer)
    initialState.selectedTable = table
    initialState.selectedMinutesInterval = 15

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.update = { timer, newMinutesInterval, newTable in
        #expect(timer == originalTimer)
        #expect(newMinutesInterval == 15)
        #expect(newTable == table)
        return updatedTimer
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateTimer(updatedTimer)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withNilValues_passesNilToUseCase() async {
    let originalTimer = createTimer()
    let updatedTimer = createTimer(id: originalTimer.id)
    var dismissCalled = false

    var initialState = Feature.State(timer: originalTimer)
    initialState.selectedTable = nil
    initialState.selectedMinutesInterval = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.update = { timer, newMinutesInterval, newTable in
        #expect(timer == originalTimer)
        #expect(newMinutesInterval == nil)
        #expect(newTable == nil)
        return updatedTimer
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateTimer(updatedTimer)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_updateFailure_handlesError() async {
    let timer = createTimer()
    let error = AppError.unknown

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.update = { _, _, _ in
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.internal(.save))
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testHandleError_sendsToErrorHandler() async {
    let timer = createTimer()
    let error = AppError.unknown
    let errorInfo = error.toErrorInfo()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State(timer: timer)) {
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

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesSelectedTable() async {
    let timer = createTimer()
    let table = createTable()

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    }

    await store.send(.binding(.set(\.selectedTable, table))) {
      $0.selectedTable = table
    }
    await store.finish()
  }

  @Test @MainActor
  func testBinding_updatesSelectedMinutesInterval() async {
    let timer = createTimer()
    let minutesInterval = 20

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    }

    await store.send(.binding(.set(\.selectedMinutesInterval, minutesInterval))) {
      $0.selectedMinutesInterval = minutesInterval
    }
    await store.finish()
  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    }

    await store.send(.delegate(.updateTimer(timer)))
    await store.finish()
  }

  // MARK: - 統合テスト

  @Test @MainActor
  func testFullWorkflow_onAppearThenSave() async {
    let originalTimer = createTimer(minutesInterval: 10)
    let updatedTimer = createTimer(id: originalTimer.id, minutesInterval: 15)
    let tables = [createTable()]
    let timeIntervals = [createTimeInterval(timeInterval: "15")]
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State(timer: originalTimer)) {
      Feature()
    } withDependencies: {
      $0.timeIntervalUseCase.fetch = {
        return timeIntervals
      }
      $0.tableUseCase.fetchAll = {
        return tables
      }
      $0.timerUseCase.update = { _, _, _ in
        return updatedTimer
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    // onAppear
    await store.send(.view(.onAppear)) {
      $0.minutesIntervals = timeIntervals.compactMap { Int($0.timeInterval) }
    }
    await store.receive(.internal(.fetchAllTableResponse(tables))) {
      $0.tables = tables
    }
    await store.receive(.internal(.setCurrentTable(nil)))

    // 選択値を変更
    await store.send(.binding(.set(\.selectedTable, tables[0]))) {
      $0.selectedTable = tables[0]
    }
    await store.send(.binding(.set(\.selectedMinutesInterval, 15))) {
      $0.selectedMinutesInterval = 15
    }

    // 保存
    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.save))
    await store.receive(.delegate(.updateTimer(updatedTimer)))

    #expect(dismissCalled)
    await store.finish()
  }

  // MARK: - エラーハンドリングのテスト

  @Test @MainActor
  func testSave_withValidationError_handlesError() async {
    let timer = createTimer()
    let validationError = TimerValidationError.invalidMinutesIntervalSelection

    var initialState = Feature.State(timer: timer)
    initialState.selectedMinutesInterval = -1  // 無効な値

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.update = { _, _, _ in
        throw validationError
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.internal(.save))
    await store.receive(.internal(.handleError(validationError.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testFetchAllTableResponse_currentTableFetchError_setsNilTable() async {
    let timer = createTimer()
    let tables = [createTable()]

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    }

    await store.send(.internal(.fetchAllTableResponse(tables))) {
      $0.tables = tables
    }
    // currentTableの取得でエラーが発生した場合、nilがセットされる
    await store.receive(.internal(.setCurrentTable(nil)))
    await store.finish()
  }

  // MARK: - 境界値テスト

  @Test @MainActor
  func testOnAppear_emptyTimeIntervals_setsEmptyMinutesIntervals() async {
    let timer = createTimer()
    let tables = [createTable()]

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    } withDependencies: {
      $0.timeIntervalUseCase.fetch = {
        return []  // 空の配列
      }
      $0.tableUseCase.fetchAll = {
        return tables
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchAllTableResponse(tables))) {
      $0.tables = tables
    }
    await store.receive(.internal(.setCurrentTable(nil)))
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_emptyTables_setsEmptyTables() async {
    let timer = createTimer()
    let timeIntervals = [createTimeInterval()]

    let store = TestStore(initialState: Feature.State(timer: timer)) {
      Feature()
    } withDependencies: {
      $0.timeIntervalUseCase.fetch = {
        return timeIntervals
      }
      $0.tableUseCase.fetchAll = {
        return []  // 空の配列
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchAllTableResponse([])))
    await store.receive(.internal(.setCurrentTable(nil)))
    await store.finish()
  }
}
