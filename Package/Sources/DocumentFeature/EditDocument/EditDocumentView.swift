//
//  EditDocumentView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/20.
//

import Common
import ComposableArchitecture
import Domain
import SwiftUI

@ViewAction(for: EditDocumentFeature.self)
struct EditDocumentView: View {
  @Bindable var store: StoreOf<EditDocumentFeature>

  init(store: StoreOf<EditDocumentFeature>) {
    self.store = store
  }

  var body: some View {
    RichTextView(
      content: $store.content
    )
    .navigationBarBackButtonHidden(true)
    .onAppear {
      send(.onAppear)
    }
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
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarItem(
      placement: .principal,
      content: {
        Menu {
          Button("なし") {
            send(.categorySelected(nil))
          }

          ForEach(store.categoryList, id: \.id) { category in
            Button(category.name) {
              send(.categorySelected(category))
            }
          }
        } label: {
          HStack(spacing: 4) {
            Text(store.selectedCategory?.name ?? "すべて")
              .font(.headline)
              .foregroundColor(.primary)
            Image(systemName: "chevron.down")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      },
      action: {}
    )
  }
}

#Preview {
  EditDocumentView(
    store: .init(
      initialState: .init(
        document: Document(
          content: .init(),
          text: "",
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
      )
    ) {
      EditDocumentFeature()
    }
  )
}
