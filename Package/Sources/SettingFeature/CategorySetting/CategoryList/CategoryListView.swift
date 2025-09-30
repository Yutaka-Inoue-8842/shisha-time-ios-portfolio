//
//  CategoryListView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import Common
import ComposableArchitecture
import Domain
import SwiftUI

@ViewAction(for: CategoryListFeature.self)
public struct CategoryListView: View {
  public typealias Category = Domain.Category

  @Bindable public var store: StoreOf<CategoryListFeature>

  public init(store: StoreOf<CategoryListFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      List(store.categoryList) { category in
        categoryItemView(category)
          .swipeActions {
            Button {
              send(.swipeToDelete(category))
            } label: {
              Image(systemName: "trash")
            }
          }
      }
      .animation(.default, value: store.categoryList)
      .scrollContentBackground(.hidden)
      .background(Color.primaryBackground)

      FloatingButton {
        send(.addButtonTapped)
      }
    }
    .onAppear {
      send(.onAppear)
    }
    .navigationTitle("カテゴリ一覧")
    .sheet(
      item: $store.scope(
        state: \.destination?.addCategory,
        action: \.destination.addCategory
      )
    ) { store in
      NavigationStack {
        AddCategoryView(store: store)
          .presentationDetents([.height(300)])
      }
    }
    .sheet(
      item: $store.scope(
        state: \.destination?.editCategory,
        action: \.destination.editCategory
      )
    ) { store in
      NavigationStack {
        EditCategoryView(store: store)
          .presentationDetents([.height(300)])
      }
    }
  }

  private func categoryItemView(_ category: Category) -> some View {
    Button {
      send(.editCategoryTapped(category))
    } label: {
      Text(category.name)
        .font(.system(size: 18, weight: .medium))
        .foregroundStyle(Color.primaryText)
    }
  }
}

#Preview {
  CategoryListView(
    store: .init(initialState: .init()) {
      CategoryListFeature()
    }
  )
}
