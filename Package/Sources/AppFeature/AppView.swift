//
//  AppFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/03.
//

import AppTabFeature
import ComposableArchitecture
import SwiftUI

@ViewAction(for: AppFeature.self)
public struct AppView: View {

  @Bindable public var store: StoreOf<AppFeature>

  public init(store: StoreOf<AppFeature>) {
    self.store = store
  }

  public var body: some View {
    AppTabView(
      store: store.scope(
        state: \.appTab,
        action: \.appTab
      )
    )
    .onAppear {
      send(.onAppear)
      UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .sound, .badge]
      ) { _, _ in }
    }
    .alert($store.scope(state: \.alert, action: \.alert))
  }
}

#Preview {
  AppView(
    store: .init(
      initialState: .init()
    ) {
      AppFeature()
    }
  )
}
