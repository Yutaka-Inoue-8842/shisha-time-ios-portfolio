//
//  CharcoalTimerFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/30.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import SettingFeature
import Testing

@testable import CharcoalTimerFeature

@MainActor
struct CharcoalTimerFeatureTests {
  typealias Feature = CharcoalTimerFeature
  typealias Timer = Feature.Timer

  // MARK: - Mock Data Creation

  private func createTimer(
    id: String = UUID().uuidString,
    name: String = "テストタイマー",
    minutes: Int = 10,
    nextCheckTime: Date = Date()
  ) -> Timer {
    Timer(
      id: id,
      nextCheckTime: .init(nextCheckTime),
      minutesInterval: minutes,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_fetchesTimersAndStartsTimer() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: [], nextToken: nil)
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchTimer))
    await store.receive(.internal(.startTimer))
    await store.receive(.internal(.fetchTimerResponse([]))) {
      $0.isTimerUpdate.toggle()
    }
    await store.receive(.internal(.timerTick)) {
      $0.isTimerUpdate.toggle()
    }

    await store.send(.internal(.stopTimer))
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_withoutNextToken_doesNothing() async {
    var initialState = Feature.State()
    initialState.nextToken = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.loadMore))
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_withNextToken_startsLoading() async {
    var initialState = Feature.State()
    initialState.nextToken = "testToken"

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetchMore = { nextToken, limit in
        #expect(nextToken == "testToken")
        #expect(limit == 20)
        return .init(items: [], nextToken: nil)
      }
    }

    await store.send(.view(.loadMore)) {
      $0.isLoadingMore = true
    }
    await store.receive(.internal(.fetchMoreTimer))
    await store.receive(.internal(.fetchMoreTimerResponse([], nil))) {
      $0.isLoadingMore = false
      $0.nextToken = nil
    }
    await store.finish()
  }

  @Test @MainActor
  func testLoadMore_whileLoading_doesNothing() async {
    var initialState = Feature.State()
    initialState.nextToken = "testToken"
    initialState.isLoadingMore = true

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.loadMore))
    await store.finish()
  }

  @Test @MainActor
  func testCheckButtonTapped_resetsTimer() async {
    let timer = createTimer()
    let resetTimer = createTimer(id: timer.id, name: "リセット済み")

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.reset = { _ in
        return resetTimer
      }
    }

    await store.send(.view(.checkButtonTapped(timer)))
    await store.receive(.internal(.updateTimer(resetTimer)))
    await store.finish()
  }

  @Test @MainActor
  func testCheckButtonTapped_onFailure_handlesError() async {
    let timer = createTimer()
    let error = AppError.unknown

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.reset = { _ in
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.checkButtonTapped(timer)))
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testTimerTapped_navigatesToEditScreen() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.timerTapped(timer))) {
      $0.destination = .editCharcoalTimer(.init(timer: timer))
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddButtonTapped_navigatesToAddScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addCharcoalTimer(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testSwipeToDelete_deletesTimer() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.delete = { _ in
        // 削除成功
      }
    }

    await store.send(.view(.swipeToDelete(timer)))
    await store.receive(.internal(.deleteTimer(timer)))
    await store.finish()
  }

  @Test @MainActor
  func testSwipeToDelete_onFailure_handlesError() async {
    let timer = createTimer()
    let error = AppError.unknown

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.delete = { _ in
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.view(.swipeToDelete(timer)))
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testSettingButtonTapped_navigatesToSettingMenu() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.settingButtonTapped)) {
      $0.destination = .settingMenu(.init())
    }
    await store.finish()
  }

  // MARK: - Internalアクション

  @Test @MainActor
  func testFetchTimer_resetsStateAndFetches() async {
    var initialState = Feature.State()
    initialState.nextToken = "oldToken"
    initialState.isLoadingMore = true

    let timers = [createTimer()]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: timers, nextToken: "newToken")
      }
    }

    await store.send(.internal(.fetchTimer)) {
      $0.nextToken = nil
      $0.isLoadingMore = false
    }
    await store.receive(.internal(.fetchTimerResponse(timers))) {
      $0.timerList = timers
      $0.isTimerUpdate.toggle()
    }
    await store.receive(.internal(.setNextToken("newToken"))) {
      $0.nextToken = "newToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchTimer_withoutNextToken_doesNotSetToken() async {
    let timers = [createTimer()]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { _ in
        return .init(items: timers, nextToken: nil)
      }
    }

    await store.send(.internal(.fetchTimer))
    await store.receive(.internal(.fetchTimerResponse(timers))) {
      $0.timerList = timers
      $0.isTimerUpdate.toggle()
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchTimer_onFailure_handlesError() async {
    let error = AppError.unknown

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { _ in
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.internal(.fetchTimer))
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testFetchTimerResponse_updatesState() async {
    let timers = [createTimer()]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchTimerResponse(timers))) {
      $0.timerList = timers
      $0.isTimerUpdate.toggle()
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreTimer_withoutNextToken_stopsLoading() async {
    var initialState = Feature.State()
    initialState.nextToken = nil

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.fetchMoreTimer))
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreTimer_withNextToken_fetches() async {
    var initialState = Feature.State()
    initialState.nextToken = "testToken"

    let moreTimers = [createTimer()]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetchMore = { nextToken, limit in
        #expect(nextToken == "testToken")
        #expect(limit == 20)
        return .init(items: moreTimers, nextToken: "nextToken")
      }
    }

    await store.send(.internal(.fetchMoreTimer))
    await store.receive(.internal(.fetchMoreTimerResponse(moreTimers, "nextToken"))) {
      $0.isLoadingMore = false
      $0.timerList.append(contentsOf: moreTimers)
      $0.nextToken = "nextToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreTimer_onFailure_handlesError() async {
    var initialState = Feature.State()
    initialState.nextToken = "testToken"
    let error = AppError.unknown

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetchMore = { _, _ in
        throw error
      }
      $0.errorHandler.send = { _ in }
    }

    await store.send(.internal(.fetchMoreTimer))
    await store.receive(.internal(.handleError(error.toErrorInfo())))
    await store.finish()
  }

  @Test @MainActor
  func testFetchMoreTimerResponse_appendsAndSorts() async {
    let timer1 = createTimer(id: "1", nextCheckTime: Date().addingTimeInterval(100))
    let timer2 = createTimer(id: "2", nextCheckTime: Date().addingTimeInterval(50))
    let timer3 = createTimer(id: "3", nextCheckTime: Date().addingTimeInterval(200))

    var initialState = Feature.State()
    initialState.timerList = [timer1]
    initialState.isLoadingMore = true
    initialState.nextToken = "currentToken"

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.fetchMoreTimerResponse([timer2, timer3], "newToken"))) {
      $0.isLoadingMore = false
      $0.timerList.append(contentsOf: [timer2, timer3])
      $0.nextToken = "newToken"
      // ソートされることを確認（nextCheckTimeの早い順）
      $0.timerList.sort { $0.nextCheckTime < $1.nextCheckTime }
    }
    await store.finish()
  }

  @Test @MainActor
  func testSetNextToken_updatesToken() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.setNextToken("newToken"))) {
      $0.nextToken = "newToken"
    }
    await store.finish()
  }

  @Test @MainActor
  func testTimerTick_togglesUpdateFlag() async {
    var initialState = Feature.State()
    initialState.isTimerUpdate = false

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.timerTick)) {
      $0.isTimerUpdate = true
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddTimer_addsAndSorts() async {
    let timer1 = createTimer(id: "1", nextCheckTime: Date().addingTimeInterval(100))
    let timer2 = createTimer(id: "2", nextCheckTime: Date().addingTimeInterval(50))

    var initialState = Feature.State()
    initialState.timerList = [timer1]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.addTimer(timer2))) {
      $0.timerList.append(timer2)
      // ソートされることを確認（nextCheckTimeの早い順）
      $0.timerList.sort { $0.nextCheckTime < $1.nextCheckTime }
    }
    await store.finish()
  }

  @Test @MainActor
  func testUpdateTimer_updatesExistingTimer() async {
    let originalTimer = createTimer(id: "test", name: "オリジナル")
    let updatedTimer = createTimer(id: "test", name: "更新済み")

    var initialState = Feature.State()
    initialState.timerList = [originalTimer]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateTimer(updatedTimer)))
    await store.finish()
  }

  @Test @MainActor
  func testUpdateTimer_nonExistentTimer_doesNothing() async {
    let originalTimer = createTimer(id: "original")
    let nonExistentTimer = createTimer(id: "nonExistent")

    var initialState = Feature.State()
    initialState.timerList = [originalTimer]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateTimer(nonExistentTimer)))
    await store.finish()
  }

  @Test @MainActor
  func testDeleteTimer_removesExistingTimer() async {
    let timer = createTimer()
    var initialState = Feature.State()
    initialState.timerList = [timer]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteTimer(timer))) {
      if let index = $0.timerList.firstIndex(where: { $0.id == timer.id }) {
        $0.timerList.remove(at: index)
      }
    }
    await store.finish()
  }

  @Test @MainActor
  func testDeleteTimer_nonExistentTimer_doesNothing() async {
    let originalTimer = createTimer(id: "original")
    let nonExistentTimer = createTimer(id: "nonExistent")

    var initialState = Feature.State()
    initialState.timerList = [originalTimer]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteTimer(nonExistentTimer)))
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

  // MARK: - Destinationアクション

  @Test @MainActor
  func testDestination_addCharcoalTimer_delegate_addsTimer() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addCharcoalTimer(.init())
    }

    await store.send(.destination(.presented(.addCharcoalTimer(.delegate(.addTimer(timer))))))
    await store.receive(.internal(.addTimer(timer))) {
      $0.timerList.append(timer)
      $0.timerList.sort { $0.nextCheckTime < $1.nextCheckTime }
    }
    await store.finish()
  }

  @Test @MainActor
  func testDestination_editCharcoalTimer_delegate_updatesTimer() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.timerTapped(timer))) {
      $0.destination = .editCharcoalTimer(.init(timer: timer))
    }
    await store.send(.destination(.presented(.editCharcoalTimer(.delegate(.updateTimer(timer))))))
    await store.receive(.internal(.updateTimer(timer)))
    await store.finish()
  }

  @Test @MainActor
  func testDestination_dismiss_refetchesTimers() async {
    let timer = createTimer()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.timerUseCase.fetch = { limit in
        #expect(limit == 20)
        return .init(items: [], nextToken: nil)
      }
    }

    await store.send(.view(.timerTapped(timer))) {
      $0.destination = .editCharcoalTimer(.init(timer: timer))
    }
    await store.send(.destination(.dismiss)) {
      $0.destination = nil
    }
    await store.receive(.internal(.fetchTimer))
    await store.receive(.internal(.fetchTimerResponse([]))) {
      $0.isTimerUpdate.toggle()
    }
    await store.finish()
  }
}
