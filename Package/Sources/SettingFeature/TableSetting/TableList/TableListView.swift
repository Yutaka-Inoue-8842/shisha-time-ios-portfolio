//
//  TableListView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/23.
//

import Common
import ComposableArchitecture
import SwiftUI

@ViewAction(for: TableListFeature.self)
struct TableListView: View {

  @Bindable var store: StoreOf<TableListFeature>

  init(store: StoreOf<TableListFeature>) {
    self.store = store
  }

  let columns = [
    GridItem(.flexible()),
    GridItem(.flexible()),
    GridItem(.flexible())
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 16) {
        if store.tableList.count <= 20 {
          // ＋ボタン（新規テーブル追加）
          Button(
            action: {
              send(.addButtonTapped)
            },
            label: {
              VStack {
                Image(systemName: "plus")
                  .font(.title)
                Text("追加")
                  .font(.caption)
              }
              .frame(maxWidth: .infinity, minHeight: 100)
              .background(Color.appPrimary.opacity(0.1))
              .foregroundColor(.appPrimary)
              .cornerRadius(12)
            }
          )
        }

        ForEach(store.tableList) { table in
          Button(
            action: {
              send(.editTableTapped(table))
            },
            label: {
              VStack {
                Text(table.name)
                  .font(.title2)
                  .bold()
                  .foregroundColor(.primary)
              }
              .frame(maxWidth: .infinity, minHeight: 100)
              .background(Color(.systemGray6))
              .cornerRadius(12)
            }
          )
        }
      }
      .animation(.default, value: store.tableList)
      .padding()
    }
    .navigationTitle("テーブルの設定")
    .onAppear {
      send(.onAppear)
    }
    .sheet(
      item: $store.scope(
        state: \.destination?.addTable,
        action: \.destination.addTable
      )
    ) { store in
      AddTableView(store: store)
        .presentationDetents([.height(300)])
    }
    .sheet(
      item: $store.scope(
        state: \.destination?.editTable,
        action: \.destination.editTable
      )
    ) { store in
      EditTableView(store: store)
        .presentationDetents([.height(300)])
    }
  }
}

#Preview {
  TableListView(
    store: .init(initialState: .init()) {
      TableListFeature()
    }
  )
}
