//
//  Constant.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/03/22.
//

public enum SortDirection: String, Sendable {
  case asc = "ASC"
  case desc = "DESC"
}

public enum Partition: String, Sendable {
  case global
}
