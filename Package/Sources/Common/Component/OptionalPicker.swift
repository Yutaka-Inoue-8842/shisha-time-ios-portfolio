//
//  OptionalPicker.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/04/27.
//

import SwiftUI

/// nilを許容するピッカー
public struct OptionalPicker<Item: Hashable, Label: View>: View {
  let title: String
  @Binding var selection: Item?
  let items: [Item]
  let label: (Item) -> Label

  public init(
    title: String,
    selection: Binding<Item?>,
    items: [Item],
    label: @escaping (Item) -> Label
  ) {
    self.title = title
    self._selection = selection
    self.items = items
    self.label = label
  }

  public var body: some View {
    Picker(title, selection: $selection) {
      Text("選択してください")
        .tag(Item?.none)

      ForEach(items, id: \.self) { item in
        label(item)
          .tag(Optional(item))
      }
    }
  }
}

#Preview {
  OptionalPicker(
    title: "数字を選んでください",
    selection: .constant(nil),
    items: [
      "item1",
      "item2",
      "item3",
      "item4",
      "item5"
    ]
  ) { name in
    Text(name)
  }
}
