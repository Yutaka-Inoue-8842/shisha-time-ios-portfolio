//
//  AddCharcoalTimerView.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/11/26.
//

import Common
import ComposableArchitecture
import Domain
import SwiftUI

@ViewAction(for: AddCharcoalTimerFeature.self)
struct AddCharcoalTimerView: View {

  @Bindable var store: StoreOf<AddCharcoalTimerFeature>

  init(store: StoreOf<AddCharcoalTimerFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      Text("タイマーを追加する")
        .font(.system(.headline))
        .frame(maxWidth: .infinity)
        .frame(height: 50)
      Divider()

      List {
        OptionalPicker(
          title: "テーブル",
          selection: $store.selectedTable,
          items: store.tables
        ) { name in
          Text(name.name)
        }
        .pickerStyle(.automatic)
        .listRowBackground(Color.secondaryBackground)

        OptionalPicker(
          title: "タイムインターバル",
          selection: $store.selectedMinutesInterval,
          items: store.minutesIntervals
        ) { name in
          Text("\(name)")
        }
        .pickerStyle(.automatic)
        .listRowBackground(Color.secondaryBackground)
      }
      .listRowSpacing(10)
      .scrollContentBackground(.hidden)
      .background(Color.primaryBackground)

      Spacer()

      PrimaryButton(
        title: "タイマーを追加"
      ) {
        send(.addCharcoalTimer)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .padding(.horizontal, 16)
    }
    .onAppear {
      send(.onAppear)
    }
  }
}
