//
//  TimeIntervalSettingFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import ComposableArchitecture
import Domain
import Foundation

/// タイムインターバル設定画面
@Reducer
public struct TimeIntervalSettingFeature: Sendable {
  public init() {}

  /// templateUseCase
  @Dependency(\.timeIntervalUseCase) var timeIntervalUseCase
  /// dismiss
  @Dependency(\.dismiss) var dismiss
  /// UUID
  @Dependency(\.uuid) var uuid

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// タイムインターバルのリスト
    var timeIntervals: [TimeIntervalData] = []
  }

  public enum Action: ViewAction, BindableAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// BindingAction
    case binding(BindingAction<State>)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// 新規作成
      case addButtonTapped
      /// Saveをタップ
      case saveButtonTapped
      /// Backをタップ
      case backButtonTapped
    }

    public enum InternalAction: Equatable {
    }
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          let result = timeIntervalUseCase.fetch()
          state.timeIntervals = result
          return .none

        case .addButtonTapped:
          state.timeIntervals.append(TimeIntervalData(id: uuid(), timeInterval: ""))
          return .none

        case .saveButtonTapped:
          let timeIntervals = state.timeIntervals.compactMap { Int($0.timeInterval) }
          timeIntervalUseCase.set(timeIntervals)
          return .run { _ in
            await dismiss()
          }

        case .backButtonTapped:
          return .run { _ in
            await dismiss()
          }
        }

      case .internal(let internalAction):
        switch internalAction {
        }
      case .binding:
        return .none
      }
    }
  }
}
