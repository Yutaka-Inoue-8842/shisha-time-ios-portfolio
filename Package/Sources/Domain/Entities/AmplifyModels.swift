import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol.

final public class AmplifyModels: AmplifyModelRegistration {
  public init() {}
  public let version: String = "4b595566e21b63a5d5e3b995d183c839"

  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Category.self)
    ModelRegistry.register(modelType: Document.self)
    ModelRegistry.register(modelType: Table.self)
    ModelRegistry.register(modelType: Timer.self)
    ModelRegistry.register(modelType: Template.self)
  }
}
