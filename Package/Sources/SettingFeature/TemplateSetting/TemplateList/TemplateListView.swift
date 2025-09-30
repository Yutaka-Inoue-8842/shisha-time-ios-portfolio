//
//  TemplateListView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/11.
//

import Common
import ComposableArchitecture
import Domain
import SwiftUI

@ViewAction(for: TemplateListFeature.self)
public struct TemplateListView: View {

  @Bindable public var store: StoreOf<TemplateListFeature>

  public init(store: StoreOf<TemplateListFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      List(store.templateList) { template in
        VStack(spacing: 0) {
          templateItemView(template)
            .swipeActions {
              Button {
                send(.swipeToDelete(template))
              } label: {
                Image(systemName: "trash")
              }
            }
        }
      }
      .animation(.default, value: store.templateList)

      FloatingButton {
        send(.addButtonTapped)
      }
    }
    .onAppear {
      send(.onAppear)
    }
    .navigationTitle("テンプレート一覧")
    .navigationDestination(
      item: $store.scope(
        state: \.destination?.addTemplate,
        action: \.destination.addTemplate
      ),
      destination: AddTemplateView.init(store:)
    )
    .navigationDestination(
      item: $store.scope(
        state: \.destination?.editTemplate,
        action: \.destination.editTemplate
      ),
      destination: EditTemplateView.init(store:)
    )
  }

  func templateItemView(_ template: Template) -> some View {
    Button {
      send(.templateTapped(template))
    } label: {
      VStack(alignment: .leading) {
        Text(template.title)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(Color.primaryText)
        Text(getTitle(attributedString: template.content.toAttributedString() ?? .init(string: "")))
          .font(.system(size: 14))
          .foregroundStyle(Color.secondaryText)
      }
    }
  }

  private func getTitle(attributedString: NSAttributedString) -> String {
    let fullString = attributedString.string
    return fullString.components(separatedBy: .newlines).first ?? ""
  }
}

#Preview {
  TemplateListView(
    store: .init(initialState: .init()) {
      TemplateListFeature()
    }
  )
}
