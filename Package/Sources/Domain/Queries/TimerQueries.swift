//
//  TimerQueries.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/09.
//

import Foundation

/// Timer関連のGraphQLクエリを管理するクラス
public struct TimerQueries {

  /// GraphQLレスポンスのデコードパス
  public static let decodePath = "listTimerByGlobalPartitionAndNextCheckTime"

  /// タイマーのフィールド選択部分
  public static var timerFields: String {
    """
    id
    nextCheckTime
    minutesInterval
    createdAt
    updatedAt
    globalPartition
    tableId
    table {
      id
      name
      createdAt
      updatedAt
      globalPartition
    }
    """
  }

  /// GraphQLクエリを生成するヘルパーメソッド
  public static func buildTimerQuery(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String? = nil
  ) -> String {
    var query = """
      query listTimerByGlobalPartitionAndNextCheckTime {
        listTimerByGlobalPartitionAndNextCheckTime(
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
            \(timerFields)
          }
          nextToken
        }
      }
      """

    return query
  }
}
