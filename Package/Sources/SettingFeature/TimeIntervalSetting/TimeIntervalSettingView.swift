//
//  TimeIntervalSettingView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import Common
import ComposableArchitecture
import SwiftUI

@ViewAction(for: TimeIntervalSettingFeature.self)
struct TimeIntervalSettingView: View {

  @Bindable var store: StoreOf<TimeIntervalSettingFeature>

  init(store: StoreOf<TimeIntervalSettingFeature>) {
    self.store = store
  }

  var body: some View {
    List {
      ForEach($store.timeIntervals, editActions: []) { $timeInterval in
        timeIntervalItemView($timeInterval.timeInterval)
      }
      if store.timeIntervals.count < 5 {
        Button {
          send(.addButtonTapped)
        } label: {
          HStack {
            Image(systemName: "plus")
            Text("Add")
              .font(.subheadline)
          }
        }
        .foregroundStyle(Color.appPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 20)
      }
    }
    .navigationTitle("タイムインターバル設定")
    .navigationBarBackButtonHidden(true)
    .navigationBarItem(
      placement: .topBarTrailing,
      content: {
        Text("Save")
          .font(.subheadline)
      },
      action: {
        send(.saveButtonTapped)
      }
    )
    .navigationBarItem(
      placement: .topBarLeading,
      content: {
        HStack(spacing: 0) {
          Image(systemName: "chevron.backward")
          Text("戻る")
            .font(.subheadline)
        }
      },
      action: {
        send(.backButtonTapped)
      }
    )
    .onAppear {
      send(.onAppear)
    }
  }

  func timeIntervalItemView(_ timeInterval: Binding<String>) -> some View {
    CommonTextField(
      placeholder: "分数を入力",
      text: timeInterval
    )
    .keyboardType(.numberPad)
  }
}

#Preview {
  TimeIntervalSettingView(
    store: .init(initialState: .init()) {
      TimeIntervalSettingFeature()
    }
  )
}
