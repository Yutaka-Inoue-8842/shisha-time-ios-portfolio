//
//  AppTabFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/04.
//

import CharcoalTimerFeature
import Common
import ComposableArchitecture
import DocumentFeature
import Foundation

@Reducer
public struct AppTabFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// タイマー一覧
    public var charcoalTimer: CharcoalTimerFeature.State = .init()
    /// ドキュメント一覧
    public var documentList: DocumentListFeature.State = .init()
    /// サイドバー
    public var sidebar: CategorySidebarFeature.State = .init()
  }

  public enum Action: ViewAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// CharcoalTimerFeatureのアクション
    case charcoalTimer(CharcoalTimerFeature.Action)
    /// DocumentListFeatureのアクション
    case documentList(DocumentListFeature.Action)
    /// サイドバーのアクション
    case sidebar(CategorySidebarFeature.Action)

    public enum ViewAction: Equatable {
      /// 初期処理
      case onAppear
      /// ハンバーガーメニューをタップ
      case hamburgerMenuTapped
    }

    public enum InternalAction: Equatable {
    }
  }

  public var body: some ReducerOf<Self> {

    Scope(state: \.charcoalTimer, action: \.charcoalTimer) {
      CharcoalTimerFeature()
    }

    Scope(state: \.documentList, action: \.documentList) {
      DocumentListFeature()
    }

    Scope(state: \.sidebar, action: \.sidebar) {
      CategorySidebarFeature()
    }

    Reduce { state, action in
      switch action {

      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          return .none

        case .hamburgerMenuTapped:
          state.sidebar.isPresented.toggle()
          return .none
        }

      case .internal:
        return .none

      case .charcoalTimer:
        return .none

      case .documentList(.delegate(.hamburgerMenuTapped)):
        state.sidebar.isPresented.toggle()
        return .none

      case .documentList:
        return .none

      case .sidebar(.delegate(.dismiss)):
        state.sidebar.isPresented = false
        return .none

      case .sidebar(.delegate(.selectCategory(let category))):
        return .send(.documentList(.view(.categorySelected(category))))

      case .sidebar:
        return .none
      }
    }
  }
}
