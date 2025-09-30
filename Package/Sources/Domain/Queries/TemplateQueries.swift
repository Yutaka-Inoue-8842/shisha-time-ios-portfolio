//
//  TemplateQueries.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/09.
//

import Foundation

/// Template関連のGraphQLクエリを管理するクラス
public struct TemplateQueries {

  /// GraphQLレスポンスのデコードパス
  public static let decodePath = "listTemplateByGlobalPartitionAndUpdatedAt"

  /// テンプレートのフィールド選択部分
  public static var templateFields: String {
    """
    id
    title
    content
    createdAt
    updatedAt
    globalPartition
    """
  }

  /// GraphQLクエリを生成するヘルパーメソッド
  public static func buildTemplateQuery(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) -> String {
    """
    query listTemplateByGlobalPartitionAndUpdatedAt {
      listTemplateByGlobalPartitionAndUpdatedAt(
        globalPartition: "\(partition.rawValue)"
        limit: \(limit)
        sortDirection: \(sortDirection.rawValue)
      ) {
        items {
          \(templateFields)
        }
      }
    }
    """
  }
}
