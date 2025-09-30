//
//  SidebarView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import ComposableArchitecture
import Domain
import SwiftUI

@ViewAction(for: CategorySidebarFeature.self)
public struct CategorySidebarView: View {
  public typealias Category = Domain.Category
  @Bindable public var store: StoreOf<CategorySidebarFeature>

  public init(store: StoreOf<CategorySidebarFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack(alignment: .leading) {
      // 背景オーバーレイ
      if store.isPresented {
        Color.black.opacity(0.3)
          .ignoresSafeArea(.all, edges: .all)
          .onTapGesture {
            send(.backgroundTapped)
          }
      }

      // サイドバー
      HStack(spacing: 0) {
        if store.isPresented {
          VStack(alignment: .leading, spacing: 0) {
            sidebarHeader

            Divider()

            sidebarCategoryItems

            Spacer()
          }
          .frame(width: 280)
          .frame(maxHeight: .infinity)
          .background(Color.white)
          .shadow(radius: 10)
          .transition(.move(edge: .leading))
        }

        Spacer()
      }
    }
    .animation(.easeInOut(duration: 0.3), value: store.isPresented)
    .onAppear {
      send(.onAppear)
    }
  }

  private var sidebarHeader: some View {
    HStack {
      Text("カテゴリ")
        .font(.system(size: 24, weight: .bold))
        .foregroundColor(.primaryText)

      Spacer()

      Button {
        send(.closeButtonTapped)
      } label: {
        Image(systemName: "xmark")
          .foregroundColor(.secondaryText)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 20)
  }

  private var sidebarCategoryItems: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        sidebarCategoryItem(nil)  // "すべて"のカテゴリ

        ForEach(store.categoryList, id: \.id) { category in
          sidebarCategoryItem(category)
            .onAppear {
              // 最後から3番目のアイテムが表示されたら次のページを読み込み
              if let lastCategory = store.categoryList.dropLast(2).last,
                category.id == lastCategory.id,
                !store.isLoadingMore,
                store.nextToken != nil
              {
                send(.loadMore)
              }
            }
        }

        // ページネーション読み込みインジケーター
        if store.isLoadingMore {
          HStack {
            Spacer()
            ProgressView()
              .scaleEffect(0.8)
            Spacer()
          }
          .padding(.vertical, 12)
        }
      }
    }
    .padding(.bottom, 8)
  }

  private func sidebarCategoryItem(_ category: Category?) -> some View {
    Button {
      send(.categoryTapped(category))
    } label: {
      HStack(spacing: 16) {
        Image(systemName: category == nil ? "tray.full" : "folder")
          .foregroundColor(.appPrimary)
          .frame(width: 20)

        Text(category?.name ?? "すべて")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(.primaryText)

        Spacer()

        if store.selectedCategory?.id == category?.id || (store.selectedCategory == nil && category == nil) {
          Image(systemName: "checkmark")
            .foregroundColor(.appPrimary)
            .font(.system(size: 12, weight: .bold))
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        (store.selectedCategory?.id == category?.id || (store.selectedCategory == nil && category == nil))
          ? Color.appPrimary.opacity(0.1)
          : Color.clear
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  CategorySidebarView(
    store: .init(initialState: .init(isPresented: true)) {
      CategorySidebarFeature()
    }
  )
}
