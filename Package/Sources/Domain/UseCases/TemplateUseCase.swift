//
//  TemplateUseCase.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/22.
//

import ComposableArchitecture
import Extension
import Foundation

/// TemplateUseCase
@DependencyClient
public struct TemplateUseCase: Sendable {
  /// データを作成
  public var create: @Sendable (_ title: String, _ content: NSAttributedString) async throws -> Template
  /// すべてのデータを取得
  public var fetchAll: @Sendable () async throws -> [Template]
  /// データを更新
  public var update: @Sendable (_ template: Template, _ newTitle: String, _ newContent: NSAttributedString) async throws -> Template
  /// データを削除
  public var delete: @Sendable (_ template: Template) async throws -> Void
}

extension TemplateUseCase {
  /// バリデーション（コンテンツ）
  public static func validate(content: NSAttributedString) throws -> String {
    guard let targetContent = content.toString() else {
      throw TemplateValidationError.invalidContent
    }
    return targetContent
  }

  /// バリデーション（タイトル）
  public static func validate(title: String) throws {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedTitle.isEmpty else {
      throw TemplateValidationError.invalidTitleEmpty
    }

    guard trimmedTitle.count <= 50 else {
      throw TemplateValidationError.invalidTitleLength
    }
  }
}

extension TemplateUseCase: DependencyKey {
  /// TemplateUseCaseのDependencyKey
  public static let liveValue: TemplateUseCase = {
    let repository = TemplateRepositoryImpl()
    return Self(
      create: { title, content in
        try TemplateUseCase.validate(title: title)
        let targetContent = try TemplateUseCase.validate(content: content)
        let template = Template(
          title: title,
          content: targetContent,
          createdAt: .init(Date()),
          updatedAt: .init(Date())
        )
        try await repository.create(template)
        return template
      },
      fetchAll: {
        let list = try await repository.fetchAll(
          partition: .global,
          limit: 20,
          sortDirection: .desc
        )
        return list.items
      },
      update: { template, newTitle, newContent in
        try TemplateUseCase.validate(title: newTitle)
        let newContentString = try TemplateUseCase.validate(content: newContent)
        var targetTemplate = template
        targetTemplate.title = newTitle
        targetTemplate.content = newContentString
        targetTemplate.updatedAt = .init(Date())
        try await repository.update(targetTemplate)
        return targetTemplate
      },
      delete: { template in
        try await repository.delete(template)
      }
    )
  }()
}

extension TemplateUseCase: TestDependencyKey {
  public static let testValue: TemplateUseCase = Self()
  public static let previewValue: TemplateUseCase = Self()
}

extension DependencyValues {
  /// TemplateUseCaseのDependencyValues
  public var templateUseCase: TemplateUseCase {
    get { self[TemplateUseCase.self] }
    set { self[TemplateUseCase.self] = newValue }
  }
}
