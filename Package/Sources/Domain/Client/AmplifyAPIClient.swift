//
//  AmplifyAPIClient.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/05/19.
//

@preconcurrency import Amplify
import Foundation

public actor AmplifyAPIClient {

  static let shared = AmplifyAPIClient()

  // GraphQLResponseErrorもthrowするために実装

  func query<R: Decodable>(request: GraphQLRequest<R>) async throws -> R {
    let result = try await Amplify.API.query(request: request)
    switch result {
    case .success(let data):
      return data
    case .failure(let error):
      throw error
    }
  }

  func mutate<R: Decodable>(request: GraphQLRequest<R>) async throws -> R {
    let result = try await Amplify.API.mutate(request: request)
    switch result {
    case .success(let data):
      return data
    case .failure(let error):
      throw error
    }
  }
}
