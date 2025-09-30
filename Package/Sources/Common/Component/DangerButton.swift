//
//  DangerButton.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/25.
//

import SwiftUI

public struct DangerButton: View {
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
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(Color.red)
        .foregroundColor(.white)
        .cornerRadius(10)
    }
  }
}

#Preview {
  DangerButton(
    title: "削除"
  ) {
    print("Delete Action")
  }
  .frame(height: 50)
  .padding(.horizontal, 16)
}
