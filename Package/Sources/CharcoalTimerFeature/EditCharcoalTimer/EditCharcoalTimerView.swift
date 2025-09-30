//
//  EditCharcoalTimerView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Common
import ComposableArchitecture
import Domain
import SwiftUI

@ViewAction(for: EditCharcoalTimerFeature.self)
public struct EditCharcoalTimerView: View {

  @Bindable public var store: StoreOf<EditCharcoalTimerFeature>

  public init(store: StoreOf<EditCharcoalTimerFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(spacing: 0) {
      Text("タイマーを編集")
        .font(.system(.headline))
        .frame(maxWidth: .infinity)
        .frame(height: 50)
      Divider()

      List {
        OptionalPicker(
          title: "テーブル",
          selection: $store.selectedTable,
          items: store.tables
        ) { table in
          Text(table.name)
        }
        .pickerStyle(.automatic)
        .listRowBackground(Color.secondaryBackground)

        OptionalPicker(
          title: "タイムインターバル",
          selection: $store.selectedMinutesInterval,
          items: store.minutesIntervals
        ) { interval in
          Text("\(interval)分")
        }
        .pickerStyle(.automatic)
        .listRowBackground(Color.secondaryBackground)
      }
      .listRowSpacing(10)
      .scrollContentBackground(.hidden)
      .background(Color.primaryBackground)

      Spacer()

      PrimaryButton(
        title: "タイマーを更新"
      ) {
        send(.saveButtonTapped)
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

#Preview {
  EditCharcoalTimerView(
    store: .init(
      initialState: .init(
        timer: .init(
          nextCheckTime: .init(Date()),
          minutesInterval: 10,
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
      )
    ) {
      EditCharcoalTimerFeature()
    }
  )
}
