//
//  SampleDataProvider.swift
//  Package
//
//  Created by Claude Code on 2025/10/14.
//

import Amplify
import Foundation

/// オンメモリRepository用のサンプルデータプロバイダー
public struct SampleDataProvider {

  // MARK: - Sample Data Generation

  /// サンプルのCategoryデータを生成
  public static func sampleCategories() -> [Category] {
    let now = Temporal.DateTime.now()
    return [
      Category(
        id: "sample-category-1",
        name: "お気に入り",
        createdAt: now,
        updatedAt: now
      ),
      Category(
        id: "sample-category-2",
        name: "試したいフレーバー",
        createdAt: now,
        updatedAt: now
      ),
      Category(
        id: "sample-category-3",
        name: "セットアップメモ",
        createdAt: now,
        updatedAt: now
      )
    ]
  }

  /// サンプルのTableデータを生成
  public static func sampleTables() -> [Table] {
    let now = Temporal.DateTime.now()
    return [
      Table(
        id: "sample-table-1",
        name: "テーブル1",
        createdAt: now,
        updatedAt: now
      ),
      Table(
        id: "sample-table-2",
        name: "テーブル2",
        createdAt: now,
        updatedAt: now
      ),
      Table(
        id: "sample-table-3",
        name: "テーブル3",
        createdAt: now,
        updatedAt: now
      )
    ]
  }

  /// サンプルのTemplateデータを生成
  public static func sampleTemplates() -> [Template] {
    let now = Temporal.DateTime.now()
    return [
      Template(
        title: "基本セットアップ",
        content: "• ボウルに水を入れる\n• 炭を準備する\n• フレーバーを詰める",
        createdAt: now,
        updatedAt: now
      ),
      Template(
        title: "クールセッション",
        content: "• 氷を多めに入れる\n• ミント系フレーバー\n• 低温で楽しむ",
        createdAt: now,
        updatedAt: now
      )
    ]
  }

  /// サンプルのDocumentデータを生成（カテゴリ付き）
  public static func sampleDocuments(categories: [Category]) -> [Document] {
    let now = Temporal.DateTime.now()
    guard categories.count >= 3 else { return [] }

    let category1 = categories[0]
    let category2 = categories[1]

    return [
      Document(
        content: NSAttributedString("ダブルアップル + ミントの組み合わせが最高！").toString() ?? "",
        text: "ダブルアップル + ミントの組み合わせが最高！",
        category: category1,
        createdAt: now,
        updatedAt: now
      ),
      Document(
        content: NSAttributedString("グレープフルーツフレーバーを試してみたい。爽やかで夏向き。").toString() ?? "",
        text: "グレープフルーツフレーバーを試してみたい。爽やかで夏向き。",
        category: category2,
        createdAt: now,
        updatedAt: now
      ),
      Document(
        content: NSAttributedString("炭は3個がベスト。熱くなりすぎず、ちょうどいい温度。").toString() ?? "",
        text: "炭は3個がベスト。熱くなりすぎず、ちょうどいい温度。",
        category: category1,
        createdAt: now,
        updatedAt: now
      )
    ]
  }

  /// サンプルのTimerデータを生成（テーブル付き）
  public static func sampleTimers(tables: [Table]) -> [Timer] {
    let now = Temporal.DateTime.now()
    let futureTime = Calendar.current.date(byAdding: .minute, value: 10, to: Date()) ?? Date()

    guard tables.count >= 2 else { return [] }

    let table1 = tables[0]
    let table2 = tables[1]

    return [
      Timer(
        nextCheckTime: Temporal.DateTime(futureTime),
        minutesInterval: 10,
        table: table1,
        createdAt: now,
        updatedAt: now
      ),
      Timer(
        nextCheckTime: Temporal.DateTime(futureTime),
        minutesInterval: 15,
        table: table2,
        createdAt: now,
        updatedAt: now
      )
    ]
  }
}
