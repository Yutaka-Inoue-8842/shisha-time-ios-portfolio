//
//  TimeIntervalSettingFeatureTests.swift
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
struct TimeIntervalSettingFeatureTests {
  typealias Feature = TimeIntervalSettingFeature

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_fetchesAndSetsTimeIntervals() async {
    let uuid1 = UUID()
    let uuid2 = UUID()
    let uuid3 = UUID()
    let timeIntervals = [
      TimeIntervalData(id: uuid1, timeInterval: "5"),
      TimeIntervalData(id: uuid2, timeInterval: "10"),
      TimeIntervalData(id: uuid3, timeInterval: "15")
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.timeIntervalUseCase.fetch = {
        timeIntervals
      }
    }

    await store.send(.view(.onAppear)) {
      $0.timeIntervals = [
        TimeIntervalData(id: uuid1, timeInterval: "5"),
        TimeIntervalData(id: uuid2, timeInterval: "10"),
        TimeIntervalData(id: uuid3, timeInterval: "15")
      ]
    }
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_withEmptyTimeIntervals() async {
    let uuid = UUID()
    let timeIntervals: [TimeIntervalData] = [
      TimeIntervalData(id: uuid, timeInterval: String(1))
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.timeIntervalUseCase.fetch = {
        timeIntervals
      }
    }

    await store.send(.view(.onAppear)) {
      $0.timeIntervals = timeIntervals
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddButtonTapped_addsEmptyTimeInterval() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.timeIntervalUseCase.fetch = {
        []
      }
    }

    await store.send(.view(.addButtonTapped)) {
      $0.timeIntervals = [
        TimeIntervalData(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, timeInterval: "")
      ]
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddButtonTapped_addsToExistingList() async {
    var initialState = Feature.State()
    initialState.timeIntervals = [TimeIntervalData(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, timeInterval: "10")]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
    }

    await store.send(.view(.addButtonTapped)) {
      $0.timeIntervals = [
        TimeIntervalData(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, timeInterval: "10"),
        TimeIntervalData(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, timeInterval: "")
      ]

    }

    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_savesValidTimeIntervalsAndDismisses() async {
    let validTimeIntervals = [
      TimeIntervalData(timeInterval: "5"),
      TimeIntervalData(timeInterval: "10"),
      TimeIntervalData(timeInterval: "15")
    ]
    let savedTimeIntervals = LockIsolated<[Int]?>(nil)
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.timeIntervals = validTimeIntervals

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.timeIntervalUseCase.set = { intervals in
        savedTimeIntervals.setValue(intervals)
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.saveButtonTapped))

    #expect(savedTimeIntervals.value == [5, 10, 15])
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_filtersOutInvalidValues() async {
    let mixedTimeIntervals = [
      TimeIntervalData(timeInterval: "5"),
      TimeIntervalData(timeInterval: "invalid"),
      TimeIntervalData(timeInterval: "10"),
      TimeIntervalData(timeInterval: ""),
      TimeIntervalData(timeInterval: "15")
    ]
    let savedTimeIntervals = LockIsolated<[Int]?>(nil)
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.timeIntervals = mixedTimeIntervals

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.timeIntervalUseCase.set = { intervals in
        savedTimeIntervals.setValue(intervals)
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.saveButtonTapped))

    #expect(savedTimeIntervals.value == [5, 10, 15])
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_withEmptyList() async {
    let savedTimeIntervals = LockIsolated<[Int]?>(nil)
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.timeIntervalUseCase.set = { intervals in
        savedTimeIntervals.setValue(intervals)
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.saveButtonTapped))

    #expect(savedTimeIntervals.value == [])
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testBackButtonTapped_callsDismiss() async {
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
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
    } withDependencies: {
      $0.uuid = .incrementing
    }

    // InternalActionは現在空なので、この段階では特にテストするものがない
    // 将来的に内部アクションが追加された場合にはここにテストを追加

    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesTimeIntervals() async {
    let newTimeIntervals = [TimeIntervalData(timeInterval: "20")]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
    }

    await store.send(.binding(.set(\.timeIntervals, newTimeIntervals))) {
      $0.timeIntervals = newTimeIntervals
    }
    await store.finish()
  }

  // MARK: - State初期化テスト

  @Test @MainActor
  func testStateInitialization() async {
    let state = Feature.State()

    #expect(state.timeIntervals.isEmpty)
  }

  // MARK: - TimeIntervalData構造体テスト

  @Test @MainActor
  func testTimeIntervalData_initialization() async {
    let data = TimeIntervalData(timeInterval: "10")

    #expect(data.timeInterval == "10")
    #expect(data.id != UUID())  // UUIDは毎回異なる値を生成する
  }

  @Test @MainActor
  func testTimeIntervalData_hashable() async {
    let data1 = TimeIntervalData(timeInterval: "10")
    let data2 = TimeIntervalData(timeInterval: "10")

    // 異なるIDを持つので、異なるハッシュ値になる
    #expect(data1.hashValue != data2.hashValue)
  }

  // MARK: - 複合テスト

  @Test @MainActor
  func testCompleteFlow_onAppearThenAddThenSave() async {
    let uuid1 = UUID()
    let uuid2 = UUID()
    let initialTimeIntervals = [
      TimeIntervalData(id: uuid1, timeInterval: "5"),
      TimeIntervalData(id: uuid2, timeInterval: "10")
    ]
    let savedTimeIntervals = LockIsolated<[Int]?>(nil)
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.uuid = .incrementing
      $0.timeIntervalUseCase.fetch = {
        initialTimeIntervals
      }
      $0.timeIntervalUseCase.set = { intervals in
        savedTimeIntervals.setValue(intervals)
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    // onAppear
    await store.send(.view(.onAppear)) {
      $0.timeIntervals = [
        TimeIntervalData(id: uuid1, timeInterval: "5"),
        TimeIntervalData(id: uuid2, timeInterval: "10")
      ]
    }

    // add button tapped
    await store.send(.view(.addButtonTapped)) {
      $0.timeIntervals.append(TimeIntervalData(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, timeInterval: ""))
    }

    // 新しい値を入力（binding）
    await store.send(.binding(.set(\.timeIntervals[2], TimeIntervalData(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, timeInterval: "15")))) {
      $0.timeIntervals[2] = TimeIntervalData(id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!, timeInterval: "15")
    }

    // save button tapped
    await store.send(.view(.saveButtonTapped))

    #expect(dismissCalled)
    await store.finish()
  }
}
