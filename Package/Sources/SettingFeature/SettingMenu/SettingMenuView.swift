//
//  SettingMenuView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import Common
import ComposableArchitecture
import SwiftUI

@ViewAction(for: SettingMenuFeature.self)
public struct SettingMenuView: View {

  @Bindable public var store: StoreOf<SettingMenuFeature>

  public init(store: StoreOf<SettingMenuFeature>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      List {
        Section(header: Text("タイマー")) {

          Button(
            action: {
              send(.tableButtonTapped)
            },
            label: {
              Text("テーブル")
                .foregroundStyle(Color.primaryText)
            }
          )

          Button(
            action: {
              send(.timeIntervalButtonTapped)
            },
            label: {
              Text("タイムインターバル")
                .foregroundStyle(Color.primaryText)
            }
          )
        }

        Section(header: Text("ドキュメント")) {
          Button(
            action: {
              send(.templateButtonTapped)
            },
            label: {
              Text("テンプレート")
                .foregroundStyle(Color.primaryText)
            }
          )

          Button(
            action: {
              send(.categoryButtonTapped)
            },
            label: {
              Text("カテゴリ")
                .foregroundStyle(Color.primaryText)
            }
          )
        }
      }
      .onAppear {
        send(.onAppear)
      }
      .navigationBarItem(
        placement: .topBarLeading,
        content: {
          Image(systemName: "chevron.down")
        },
        action: {
          send(.backButtonTapped)
        }
      )
      .navigationTitle("設定")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(
        item: $store.scope(
          state: \.destination?.tableList,
          action: \.destination.tableList
        ),
        destination: TableListView.init(store:)
      )
      .navigationDestination(
        item: $store.scope(
          state: \.destination?.timeIntervalSetting,
          action: \.destination.timeIntervalSetting
        ),
        destination: TimeIntervalSettingView.init(store:)
      )
      .navigationDestination(
        item: $store.scope(
          state: \.destination?.templateList,
          action: \.destination.templateList
        ),
        destination: TemplateListView.init(store:)
      )
      .navigationDestination(
        item: $store.scope(
          state: \.destination?.categoryList,
          action: \.destination.categoryList
        ),
        destination: CategoryListView.init(store:)
      )
    }
    .accentColor(.appPrimary)
  }
}

#Preview {
  SettingMenuView(
    store: .init(initialState: .init()) {
      SettingMenuFeature()
    }
  )
}
