//
//  UserDefaultsClient.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/17.
//

import Foundation

public final class UserDefaultsClient {
  private let userDefaults: UserDefaults

  public init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  public func getValue(forKey key: UserDefaultsKeys) -> Any? {
    userDefaults.object(forKey: key.rawValue)
  }

  public func setValue(_ value: Any?, forKey key: UserDefaultsKeys) {
    userDefaults.set(value, forKey: key.rawValue)
  }

  public func removeValue(forKey key: UserDefaultsKeys) {
    userDefaults.removeObject(forKey: key.rawValue)
  }
}

extension UserDefaultsClient {
  public enum UserDefaultsKeys: String {
    case timeIntervals
  }
}
