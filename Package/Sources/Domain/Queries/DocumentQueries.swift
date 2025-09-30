//
//  DocumentQueries.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/09.
//

import Foundation

/// Document関連のGraphQLクエリを管理するクラス
public struct DocumentQueries {

  /// GraphQLレスポンスのデコードパス
  public static let decodePath = "listDocumentByGlobalPartitionAndUpdatedAt"

  /// ドキュメントのフィールド選択部分
  public static var documentFields: String {
    """
    id
    content
    text
    categoryId
    category {
      id
      name
      createdAt
      updatedAt
      globalPartition
    }
    createdAt
    updatedAt
    globalPartition
    """
  }

  /// GraphQLクエリを生成するヘルパーメソッド
  public static func buildDocumentQuery(
    partition: Partition,
    limit: Int,
    sortDirection: SortDirection,
    nextToken: String? = nil,
    filter: String? = nil
  ) -> String {
    var query = """
      query listDocumentByGlobalPartitionAndUpdatedAt {
        listDocumentByGlobalPartitionAndUpdatedAt(
          globalPartition: "\(partition.rawValue)"
          limit: \(limit)
          sortDirection: \(sortDirection.rawValue)
      """

    if let nextToken = nextToken {
      query += "\n          nextToken: \"\(nextToken)\""
    }

    if let filter = filter {
      query += "\n          filter: \(filter)"
    }

    query += """
        ) {
          items {
            \(documentFields)
          }
          nextToken
        }
      }
      """

    return query
  }

  /// カテゴリフィルターを生成
  public static func categoryFilter(categoryId: String) -> String {
    """
    {
      categoryId: {
        eq: "\(categoryId)"
      }
    }
    """
  }

  /// 検索フィルターを生成
  public static func searchFilter(query: String) -> String {
    """
    {
      text: {
        contains: "\(query)"
      }
    }
    """
  }

  /// カテゴリ内検索フィルターを生成
  public static func categorySearchFilter(query: String, categoryId: String) -> String {
    """
    {
      and: [
        { text: { contains: "\(query)" } },
        { categoryId: { eq: "\(categoryId)" } }
      ]
    }
    """
  }
}
