//
//  TableQueries.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/09.
//

import Foundation

/// Table関連のGraphQLクエリを管理するクラス
public struct TableQueries {

  /// GraphQLレスポンスのデコードパス
  public static let decodePath = "listTableByGlobalPartitionAndUpdatedAt"

  /// テーブルのフィールド選択部分
  public static var tableFields: String {
    """
    id
    name
    createdAt
    updatedAt
    globalPartition
    """
  }

  /// GraphQLクエリを生成するヘルパーメソッド
  public static func buildTableQuery(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection
  ) -> String {
    """
    query listTableByGlobalPartitionAndUpdatedAt {
      listTableByGlobalPartitionAndUpdatedAt(
        globalPartition: "\(partition.rawValue)"
        limit: \(limit)
        sortDirection: \(sortDirection.rawValue)
      ) {
        items {
          \(tableFields)
        }
      }
    }
    """
  }
}
