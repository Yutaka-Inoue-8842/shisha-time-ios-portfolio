//
//  DocumentUseCase.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/14.
//

import Amplify
import ComposableArchitecture
import Extension
import Foundation

/// DocumentUseCase
@DependencyClient
public struct DocumentUseCase: Sendable {
  /// データを作成
  public var create: @Sendable (_ content: NSAttributedString, _ category: Category?) async throws -> Document
  /// すべてのデータを取得
  public var fetchAll: @Sendable () async throws -> PaginatedList<Document>
  /// ページネーション対応でデータを取得（初回）
  public var fetch: @Sendable (_ limit: Int) async throws -> PaginatedList<Document>
  /// ページネーション対応でデータを取得（続きページ）
  public var fetchMore: @Sendable (_ nextToken: String, _ limit: Int) async throws -> PaginatedList<Document>
  /// データを更新
  public var update: @Sendable (_ document: Document, _ newContent: NSAttributedString, _ newCategory: Category?) async throws -> Document
  /// データを削除
  public var delete: @Sendable (_ document: Document) async throws -> Void
  /// 検索クエリでドキュメントを検索（初回）
  public var search: @Sendable (_ query: String, _ limit: Int) async throws -> PaginatedList<Document>
  /// 検索クエリで追加のドキュメントを取得（nextTokenを使用）
  public var searchMore: @Sendable (_ query: String, _ nextToken: String, _ limit: Int) async throws -> PaginatedList<Document>
  /// カテゴリ内で検索クエリでドキュメントを検索（初回）
  public var searchByCategory: @Sendable (_ query: String, _ category: Category, _ limit: Int) async throws -> PaginatedList<Document>
  /// カテゴリ内で検索クエリで追加のドキュメントを取得（nextTokenを使用）
  public var searchMoreByCategory: @Sendable (_ query: String, _ category: Category, _ nextToken: String, _ limit: Int) async throws -> PaginatedList<Document>
  /// カテゴリでフィルタリングしたドキュメントを取得（初回）
  public var fetchByCategory: @Sendable (_ category: Category, _ limit: Int) async throws -> PaginatedList<Document>
  /// カテゴリでフィルタリングしたドキュメントを取得（続きページ）
  public var fetchMoreByCategory: @Sendable (_ category: Category, _ nextToken: String, _ limit: Int) async throws -> PaginatedList<Document>
}

extension DocumentUseCase {
  /// バリデーション
  public static func validate(content: NSAttributedString) throws -> (contentString: String, text: String) {
    guard let targetContent = content.toString() else {
      throw DocumentValidationError.invalidContent
    }

    let text = content.string.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !text.isEmpty else {
      throw DocumentValidationError.invalidContentEmpty
    }

    guard text.count <= 10000 else {
      throw DocumentValidationError.invalidContentLength
    }

    return (targetContent, content.string)
  }
}

extension DocumentUseCase: DependencyKey {
  /// DocumentUseCaseのDependencyKey
  public static let liveValue: DocumentUseCase = {
    let documentRepository = DocumentRepositoryImpl()
    let categoryRepository = CategoryRepositoryImpl()

    return Self(
      create: { content, category in
        let (contentString, text) = try DocumentUseCase.validate(content: content)
        var document = Document(
          content: contentString,
          text: text,
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
        document.setCategory(category)
        try await documentRepository.create(document)
        return document
      },
      fetchAll: {
        try await documentRepository.fetch(
          partition: .global,
          limit: 60,
          sortDirection: .desc
        )
      },
      fetch: { limit in
        try await documentRepository.fetch(
          partition: .global,
          limit: limit,
          sortDirection: .desc
        )
      },
      fetchMore: { nextToken, limit in
        try await documentRepository.fetchMore(
          partition: .global,
          limit: limit,
          sortDirection: .desc,
          nextToken: nextToken
        )
      },
      update: { document, newContent, newCategory in
        let (newContentString, newText) = try DocumentUseCase.validate(content: newContent)
        var targetDocument = document
        targetDocument.content = newContentString
        targetDocument.text = newText
        targetDocument.updatedAt = .init(Date())
        targetDocument.setCategory(newCategory)
        try await documentRepository.update(targetDocument)
        return targetDocument
      },
      delete: { document in
        try await documentRepository.delete(document)
      },
      search: { query, limit in
        try await documentRepository.searchDocuments(
          query: query,
          partition: .global,
          limit: limit,
          sortDirection: .desc
        )
      },
      searchMore: { query, nextToken, limit in
        try await documentRepository.searchMoreDocuments(
          query: query,
          partition: .global,
          limit: limit,
          sortDirection: .desc,
          nextToken: nextToken
        )
      },
      searchByCategory: { query, category, limit in
        try await documentRepository.searchDocumentsByCategory(
          query: query,
          categoryId: category.id,
          partition: .global,
          limit: limit,
          sortDirection: .desc
        )
      },
      searchMoreByCategory: { query, category, nextToken, limit in
        try await documentRepository.searchMoreDocumentsByCategory(
          query: query,
          categoryId: category.id,
          partition: .global,
          limit: limit,
          sortDirection: .desc,
          nextToken: nextToken
        )
      },
      fetchByCategory: { category, limit in
        try await documentRepository.fetchByCategory(
          categoryId: category.id,
          partition: .global,
          limit: limit,
          sortDirection: .desc
        )
      },
      fetchMoreByCategory: { category, nextToken, limit in
        try await documentRepository.fetchMoreByCategory(
          categoryId: category.id,
          partition: .global,
          limit: limit,
          sortDirection: .desc,
          nextToken: nextToken
        )
      }
    )
  }()
}

extension DocumentUseCase: TestDependencyKey {
  public static let testValue: DocumentUseCase = Self()
  public static let previewValue: DocumentUseCase = Self()
}

extension DependencyValues {
  /// DocumentUseCaseのDependencyValues
  public var documentUseCase: DocumentUseCase {
    get { self[DocumentUseCase.self] }
    set { self[DocumentUseCase.self] = newValue }
  }
}
