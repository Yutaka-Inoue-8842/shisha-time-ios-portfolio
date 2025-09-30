//
//  CategoryQueries.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/09.
//

import Foundation

/// Category関連のGraphQLクエリを管理するクラス
public struct CategoryQueries {

  /// GraphQLレスポンスのデコードパス
  public static let decodePath = "listCategoryByGlobalPartitionAndUpdatedAt"

  /// カテゴリのフィールド選択部分
  public static var categoryFields: String {
    """
    id
    name
    createdAt
    updatedAt
    globalPartition
    """
  }

  /// GraphQLクエリを生成するヘルパーメソッド
  public static func buildCategoryQuery(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String? = nil
  ) -> String {
    var query = """
      query listCategoryByGlobalPartitionAndUpdatedAt {
        listCategoryByGlobalPartitionAndUpdatedAt(
          globalPartition: "\(partition.rawValue)"
          limit: \(limit)
          sortDirection: \(sortDirection.rawValue)
      """

    if let nextToken = nextToken {
      query += "\n          nextToken: \"\(nextToken)\""
    }

    query += """
        ) {
          items {
            \(categoryFields)
          }
          nextToken
        }
      }
      """

    return query
  }
}
