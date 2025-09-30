//
//  PaginatedList.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/23.
//

import Amplify
import Foundation

public struct PaginatedList<ModelType: Model>: Decodable, @unchecked Sendable {
  public init(items: [ModelType], nextToken: String?) {
    self.items = items
    self.nextToken = nextToken
  }

  public let items: [ModelType]
  public let nextToken: String?
}
