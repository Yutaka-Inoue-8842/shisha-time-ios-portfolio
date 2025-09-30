//
//  AddCharcoalTimerFeatureTests.swift
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
struct AddCharcoalTimerFeatureTests {
  typealias Feature = AddCharcoalTimerFeature
  typealias Timer = Domain.Timer
  typealias Table = Domain.Table
  typealias TimeInterval = Domain.TimeIntervalData

  // MARK: - Mock Data Creation

  private func createTable(
    id: String = UUID().uuidString,
    name: String = "テーブル1",
    capacity: Int = 4
  ) -> Table {
    Table(
      id: id,
      name: name,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  private func createTimer(
    id: String = UUID().uuidString,
    name: String = "テストタイマー",
    minutes: Int = 10
  ) -> Timer {
    Timer(
      id: id,
      nextCheckTime: .init(Date()),
      minutesInterval: minutes,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  private func createTimeInterval(timeInterval: String = "10") -> TimeInterval {
    TimeInterval(
      id: UUID(),
      timeInterval: timeInterval,
    )
  }

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_fetchesTablesAndTimeIntervals() async {
    let tables = [createTable()]
    let timeIntervals = [
      createTimeInterval(timeInterval: "10"),
      createTimeInterval(timeInterval: "15")
    ]

    let store = TestStore(initialState: Feature.State()) {
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
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_tablesFetchFailure_handlesError() async {
    let error = AppError.unknown
    let timeIntervals = [createTimeInterval()]

    let store = TestStore(initialState: Feature.State()) {
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

    await store.send(.view(.onAppear)) {
      $0.minutesIntervals = timeIntervals.compactMap { Int($0.timeInterval) }
    }
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testAddCharcoalTimer_createsTimerAndDismisses() async {
    let table = createTable()
    let minutesInterval = 10
    let createdTimer = createTimer(minutes: minutesInterval)
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.selectedTable = table
    initialState.selectedMinutesInterval = minutesInterval

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.create = { minutes, selectedTable in
        #expect(minutes == minutesInterval)
        #expect(selectedTable == table)
        return createdTimer
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.addCharcoalTimer))
    await store.receive(.delegate(.addTimer(createdTimer)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testAddCharcoalTimer_withNilValues_passesNilToUseCase() async {
    let createdTimer = createTimer()
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.selectedTable = nil
    initialState.selectedMinutesInterval = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.create = { minutes, selectedTable in
        #expect(minutes == nil)
        #expect(selectedTable == nil)
        return createdTimer
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.addCharcoalTimer))
    await store.receive(.delegate(.addTimer(createdTimer)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testAddCharcoalTimer_creationFailure_handlesError() async {
    let error = AppError.unknown
    let table = createTable()
    let minutesInterval = 10

    var initialState = Feature.State()
    initialState.selectedTable = table
    initialState.selectedMinutesInterval = minutesInterval

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.create = { _, _ in
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.addCharcoalTimer))
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  // MARK: - Internalアクション

  @Test @MainActor
  func testFetchAllTableResponse_updatesTables() async {
    let tables = [createTable(), createTable(name: "テーブル2")]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchAllTableResponse(tables))) {
      $0.tables = tables
    }
    await store.finish()
  }

  @Test @MainActor
  func testHandleError_sendsToErrorHandler() async {
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

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesSelectedTable() async {
    let table = createTable()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.binding(.set(\.selectedTable, table))) {
      $0.selectedTable = table
    }
    await store.finish()
  }

  @Test @MainActor
  func testBinding_updatesSelectedMinutesInterval() async {
    let minutesInterval = 15

    let store = TestStore(initialState: Feature.State()) {
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

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.delegate(.addTimer(timer)))
    await store.finish()
  }

  // MARK: - 統合テスト

  @Test @MainActor
  func testFullWorkflow_onAppearThenAddTimer() async {
    let tables = [createTable()]
    let timeIntervals = [createTimeInterval(timeInterval: "10")]
    let createdTimer = createTimer()
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timeIntervalUseCase.fetch = {
        return timeIntervals
      }
      $0.tableUseCase.fetchAll = {
        return tables
      }
      $0.timerUseCase.create = { _, _ in
        return createdTimer
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

    // 選択値を設定
    await store.send(.binding(.set(\.selectedTable, tables[0]))) {
      $0.selectedTable = tables[0]
    }
    await store.send(.binding(.set(\.selectedMinutesInterval, 10))) {
      $0.selectedMinutesInterval = 10
    }

    // タイマー追加
    await store.send(.view(.addCharcoalTimer))
    await store.receive(.delegate(.addTimer(createdTimer)))

    #expect(dismissCalled)
    await store.finish()
  }

  // MARK: - バリデーションエラーのテスト

  @Test @MainActor
  func testAddCharcoalTimer_withValidationError_handlesError() async {
    let validationError = TimerValidationError.invalidMinutesIntervalSelection
    var initialState = Feature.State()
    initialState.selectedTable = createTable()
    initialState.selectedMinutesInterval = -1  // 無効な値

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.create = { _, _ in
        throw validationError
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.addCharcoalTimer))
    await store.receive(.internal(.handleError(validationError.toErrorInfo())))
    await store.finish()
  }
}
