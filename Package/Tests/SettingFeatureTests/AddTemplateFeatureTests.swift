//
//  AddTemplateFeatureTests.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/08/20.
//

import Common
import ComposableArchitecture
import Domain
import Foundation
import Testing

@testable import SettingFeature

@MainActor
struct AddTemplateFeatureTests {
  typealias Feature = AddTemplateFeature
  typealias Template = Domain.Template

  // MARK: - Mock Data Creation

  private func createTemplate(
    id: String = UUID().uuidString,
    title: String = "テンプレート",
    content: String = "テンプレート内容"
  ) -> Template {
    Template(
      id: id,
      title: title,
      content: content,
      createdAt: .init(Date()),
      updatedAt: .init(Date())
    )
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testHandleError_sendsErrorToHandler() async {
    let error = AppError.unknown
    let errorInfo = error.toErrorInfo()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.handleError(errorInfo)))

    #expect(sentErrorInfo.value == errorInfo)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withTitle_callsUseCaseAndSendsDelegate() async {
    let title = "テストテンプレート"
    let content = NSAttributedString(string: "テストコンテンツ")
    let createdTemplate = createTemplate(title: title, content: "テストコンテンツ")
    var dismissCalled = false

    var initialState = Feature.State()
    initialState.title = title
    initialState.content = content

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.create = { title, content in
        return createdTemplate
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.addTemplate(createdTemplate)))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withEmptyTitle_onlyCallsDismiss() async {
    let content = NSAttributedString(string: "テストコンテンツ")
    var dismissCalled = false
    let template = createTemplate()

    var initialState = Feature.State()
    initialState.title = ""
    initialState.content = content

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.create = { _, _ in
        return template
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))

    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_onFailure_reportsError() async {
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State()
    initialState.title = "テンプレート"
    initialState.content = NSAttributedString(string: "コンテンツ")

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.create = { _, _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.internal(.save))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_doesNothing() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.onAppear))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_triggersSaveInternalAction() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.save))
    await store.finish()
  }

  @Test @MainActor
  func testBackButtonTapped_callsDismiss() async {
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.view(.backButtonTapped))

    #expect(dismissCalled)
    await store.finish()
  }

  // MARK: - Bindingアクション

  @Test @MainActor
  func testBinding_updatesTitle() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.binding(.set(\.title, "新しいタイトル"))) {
      $0.title = "新しいタイトル"
    }
    await store.finish()
  }

  // TODO: NSAttributedStringがSendableに準拠していないため、以下のテストは一旦コメントアウト
  //  @Test @MainActor
  //  func testBinding_updatesContent() async {
  //    let newContent = NSAttributedString(string: "新しいコンテンツ") as @unchecked Sendable
  //    let store = TestStore(initialState: Feature.State()) {
  //      Feature()
  //    }
  //
  //    await store.send(.binding(.set(\.content, newContent))) {
  //      $0.content = newContent
  //    }
  //    await store.finish()
  //  }

  // MARK: - Delegateアクション

  @Test @MainActor
  func testDelegate_doesNothing() async {
    let template = createTemplate()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.delegate(.addTemplate(template)))
    await store.finish()
  }
}
