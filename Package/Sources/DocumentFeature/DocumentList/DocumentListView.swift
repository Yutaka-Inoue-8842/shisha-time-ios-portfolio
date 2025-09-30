//
//  DocumentListView.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/04.
//

import Common
import ComposableArchitecture
import Domain
import Extension
import SettingFeature
import SwiftUI

@ViewAction(for: DocumentListFeature.self)
public struct DocumentListView: View {

  @Bindable public var store: StoreOf<DocumentListFeature>

  public init(store: StoreOf<DocumentListFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      List(store.documentList) { document in
        VStack(spacing: 0) {
          documentItemView(document)
            .swipeActions {
              Button {
                send(.swipeToDelete(document))
              } label: {
                Image(systemName: "trash")
              }
            }
            .onAppear {
              // 最後から3番目のアイテムが表示されたら次のページを読み込み
              if let lastDocument = store.documentList.dropLast(2).last,
                document.id == lastDocument.id,
                !store.isLoadingMore,
                store.nextToken != nil
              {
                send(.loadMore)
              }
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
      }
      .animation(.default, value: store.documentList)
      .scrollContentBackground(.hidden)
      .background(Color.primaryBackground)
      .searchable(text: $store.searchQuery, prompt: "ドキュメントを検索")

      FloatingButton {
        send(.addButtonTapped)
      }
    }
    .onAppear {
      send(.onAppear)
    }
    .navigationBarItem(
      placement: .topBarLeading,
      content: {
        Image(systemName: "line.3.horizontal")
          .foregroundColor(.appPrimary)
      },
      action: {
        send(.hamburgerMenuTapped)
      }
    )
    .navigationBarItem(
      placement: .topBarTrailing,
      content: {
        Image(systemName: "gearshape")
          .foregroundColor(.appPrimary)
      },
      action: {
        send(.settingButtonTapped)
      }
    )
    .navigationTitle(store.selectedCategory?.name ?? "すべて")
    .navigationDestination(
      item: $store.scope(
        state: \.destination?.addDocument,
        action: \.destination.addDocument
      ),
      destination: AddDocumentView.init(store:)
    )
    .navigationDestination(
      item: $store.scope(
        state: \.destination?.editDocument,
        action: \.destination.editDocument
      ),
      destination: EditDocumentView.init(store:)
    )
    .fullScreenCover(
      item: $store.scope(
        state: \.destination?.settingMenu,
        action: \.destination.settingMenu
      )
    ) { store in
      SettingMenuView(store: store)
    }
  }

  private func documentItemView(_ document: Document) -> some View {
    Button {
      send(.documentTapped(document))
    } label: {
      let attributedString = document.content.toAttributedString() ?? .init(string: "")
      let title = getTitle(attributedString: attributedString)
      let contentPreview = getContentPreview(attributedString: attributedString)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(title)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(Color.primaryText)
            .lineLimit(1)

          Spacer()

          Text(document.updatedAt.foundationDate.formattedUpdateTime)
            .font(.system(size: 12, weight: .regular))
            .foregroundStyle(Color.secondaryText)
        }

        if !contentPreview.isEmpty {
          Text(contentPreview)
            .font(.system(size: 14, weight: .regular))
            .foregroundStyle(Color.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(3)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color.white)
      .cornerRadius(8)
      .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
  }

  private func getTitle(attributedString: NSAttributedString) -> String {
    let fullString = attributedString.string
    return fullString.components(separatedBy: .newlines).first ?? ""
  }

  private func getContentPreview(attributedString: NSAttributedString) -> String {
    let fullString = attributedString.string
    let lines = fullString.components(separatedBy: .newlines)

    // 2行目以降から空行をスキップして最大3行を取得
    var contentLines: [String] = []
    var lineIndex = 1  // 1行目はタイトルなので2行目から開始

    while contentLines.count < 3 && lineIndex < lines.count {
      let line = lines[lineIndex].trimmingCharacters(in: .whitespacesAndNewlines)
      if !line.isEmpty {
        contentLines.append(line)
      }
      lineIndex += 1
    }

    return contentLines.joined(separator: "\n")
  }

}

#Preview {
  DocumentListView(
    store: .init(initialState: .init()) {
      DocumentListFeature()
    }
  )
}
