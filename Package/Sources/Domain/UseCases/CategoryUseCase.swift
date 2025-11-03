//
//  CategoryUseCase.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/07/26.
//

import ComposableArchitecture
import Foundation

/// CategoryUseCase
@DependencyClient
public struct CategoryUseCase: Sendable {
  /// データを作成
  public var create: @Sendable (_ category: Category) async throws -> Category
  /// すべてのデータを取得
  public var fetchAll: @Sendable () async throws -> PaginatedList<Category>
  /// ページネーション対応でデータを取得（初回）
  public var fetch: @Sendable (_ limit: Int) async throws -> PaginatedList<Category>
  /// ページネーション対応でデータを取得（続きページ）
  public var fetchMore: @Sendable (_ nextToken: String, _ limit: Int) async throws -> PaginatedList<Category>
  /// データを更新
  public var update: @Sendable (_ category: Category) async throws -> Category
  /// データを削除
  public var delete: @Sendable (_ category: Category) async throws -> Void
}

extension CategoryUseCase {
  /// バリデーション
  public static func validate(name: String) throws {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else {
      throw CategoryValidationError.invalidNameEmpty
    }

    guard trimmedName.count <= 20 else {
      throw CategoryValidationError.invalidNameLength
    }
  }
}

extension CategoryUseCase: DependencyKey {
  /// CategoryUseCaseのDependencyKey
  public static var liveValue: CategoryUseCase {
    // 環境に応じてRepositoryを切り替え
    @Dependency(\.repositoryEnvironment) var environment

    @Sendable func getCategoryRepository() -> any CategoryRepository {
      switch environment {
      case .production:
        return CategoryRepositoryImpl()
      case .demo:
        return CategoryRepositoryDemoImpl()
      }
    }

    return Self(
      create: { category in
        try CategoryUseCase.validate(name: category.name)
        let repository = getCategoryRepository()
        try await repository.create(category)
        return category
      },
      fetchAll: {
        let repository = getCategoryRepository()
        return try await repository.fetch(
          partition: .global,
          limit: 60,
          sortDirection: .desc
        )
      },
      fetch: { limit in
        let repository = getCategoryRepository()
        return try await repository.fetch(
          partition: .global,
          limit: limit,
          sortDirection: .desc
        )
      },
      fetchMore: { nextToken, limit in
        let repository = getCategoryRepository()
        return try await repository.fetchMore(
          partition: .global,
          limit: limit,
          sortDirection: .desc,
          nextToken: nextToken
        )
      },
      update: { category in
        try CategoryUseCase.validate(name: category.name)
        let repository = getCategoryRepository()
        try await repository.update(category)
        return category
      },
      delete: { category in
        let repository = getCategoryRepository()
        try await repository.delete(category)
      }
    )
  }
}

extension CategoryUseCase: TestDependencyKey {
  public static let testValue: CategoryUseCase = Self()
  public static let previewValue: CategoryUseCase = Self()
}

extension DependencyValues {
  /// CategoryUseCaseのDependencyValues
  public var categoryUseCase: CategoryUseCase {
    get { self[CategoryUseCase.self] }
    set { self[CategoryUseCase.self] = newValue }
  }
}
