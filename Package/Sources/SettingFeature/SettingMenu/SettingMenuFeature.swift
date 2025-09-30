//
//  SettingFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import ComposableArchitecture
import Domain
import Foundation

/// 設定画面
@Reducer
public struct SettingMenuFeature: Sendable {
  public init() {}

  /// dismiss
  @Dependency(\.dismiss) var dismiss

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// 画面遷移のState
    @Presents var destination: Destination.State?
  }

  public enum Action: ViewAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// 子画面のアクション
    case destination(PresentationAction<Destination.Action>)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// テーブルボタンタップ
      case tableButtonTapped
      /// タイムインターバルタップ
      case timeIntervalButtonTapped
      /// テンプレートボタンタップ
      case templateButtonTapped
      /// カテゴリボタンタップ
      case categoryButtonTapped
      /// 戻るボタンタップ
      case backButtonTapped
    }

    public enum InternalAction: Equatable {
    }
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          return .none

        case .tableButtonTapped:
          state.destination = .tableList(.init())
          return .none

        case .timeIntervalButtonTapped:
          state.destination = .timeIntervalSetting(.init())
          return .none

        case .templateButtonTapped:
          state.destination = .templateList(.init())
          return .none

        case .categoryButtonTapped:
          state.destination = .categoryList(.init())
          return .none

        case .backButtonTapped:
          return .run { _ in
            await dismiss()
          }
        }

      case .internal(let internalAction):
        switch internalAction {
        }

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension SettingMenuFeature {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    // テーブル設定
    case tableList(TableListFeature)
    // タイムインターバル設定
    case timeIntervalSetting(TimeIntervalSettingFeature)
    // テンプレート設定
    case templateList(TemplateListFeature)
    // カテゴリ設定
    case categoryList(CategoryListFeature)
  }
}
