//
//  FloatingButton.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/11/23.
//

import SwiftUI

public struct FloatingButton: View {

  let action: () -> Void

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        Button {
          action()
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 24))
            .foregroundColor(.white)
            .padding(20)
            .background(Color.appPrimary)
            .clipShape(Circle())
            .shadow(radius: 10)
        }
      }
      .padding(.trailing, 20)
    }
    .padding(.bottom, 20)
  }
}

#Preview {
  FloatingButton {}
}
