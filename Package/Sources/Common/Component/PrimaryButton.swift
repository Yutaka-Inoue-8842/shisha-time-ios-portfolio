//
//  PrimaryButton.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/11.
//

import SwiftUI

public struct PrimaryButton: View {
  public init(
    title: String,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.action = action
  }
  var title: String
  var action: () -> Void

  public var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color.appPrimary)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
  }
}

#Preview {
  PrimaryButton(
    title: "プレビュー"
  ) {
    print("Action")
  }
}
