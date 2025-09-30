//
//  AppTabView.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/04.
//

import CharcoalTimerFeature
import Common
import ComposableArchitecture
import DocumentFeature
import SwiftUI

@ViewAction(for: AppTabFeature.self)
public struct AppTabView: View {

  public let store: StoreOf<AppTabFeature>

  public init(store: StoreOf<AppTabFeature>) {
    self.store = store
  }

  @State var selection = 1

  public var body: some View {
    ZStack {
      TabView(selection: $selection) {
        NavigationStack {
          CharcoalTimerView(
            store: store.scope(
              state: \.charcoalTimer,
              action: \.charcoalTimer
            )
          )
        }
        .tabItem {
          Label("タイマー", systemImage: "timer")
        }
        .tag(1)

        NavigationStack {
          DocumentListView(
            store: store.scope(
              state: \.documentList,
              action: \.documentList
            )
          )
        }
        .tabItem {
          Label("資料", systemImage: "document")
        }
        .tag(2)
      }
      .accentColor(.appPrimary)

      CategorySidebarView(
        store: store.scope(state: \.sidebar, action: \.sidebar)
      )
    }
  }
}

#Preview {
  AppTabView(
    store: .init(
      initialState: .init()
    ) {
      AppTabFeature()
    }
  )
}
