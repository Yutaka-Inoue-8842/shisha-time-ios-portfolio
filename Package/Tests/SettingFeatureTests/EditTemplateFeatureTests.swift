//
//  EditTemplateFeatureTests.swift
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
struct EditTemplateFeatureTests {
  typealias Feature = EditTemplateFeature
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

  // MARK: - State初期化テスト

  @Test @MainActor
  func testStateInitialization_setsTemplateAndFields() async {
    let template = createTemplate(title: "テストテンプレート", content: "テストコンテンツ")
    let state = Feature.State(template: template)

    #expect(state.template == template)
    #expect(state.title == "テストテンプレート")
  }

  @Test @MainActor
  func testStateInitialization_withEmptyContent() async {
    let template = createTemplate(title: "テストテンプレート", content: "")
    let state = Feature.State(template: template)

    #expect(state.template == template)
    #expect(state.title == "テストテンプレート")
    #expect(state.content.string.isEmpty)
  }

  // MARK: - 基本の内部アクション

  @Test @MainActor
  func testHandleError_sendsErrorToHandler() async {
    let template = createTemplate()
    let error = AppError.unknown
    let errorInfo = error.toErrorInfo()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State(template: template)) {
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
  func testSave_withTitleChange_callsUseCaseAndSendsDelegate() async {
    let originalTemplate = createTemplate(title: "オリジナル", content: "オリジナル内容")
    let updatedTitle = "更新されたタイトル"
    let updatedTemplate = createTemplate(id: originalTemplate.id, title: updatedTitle, content: "オリジナル内容")
    var dismissCalled = false

    var initialState = Feature.State(template: originalTemplate)
    initialState.title = updatedTitle

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.update = { template, newTitle, newContent in
        return updatedTemplate
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateTemplate(updatedTemplate)))
    #expect(dismissCalled)
    await store.finish()
  }

  @Test @MainActor
  func testSave_withContentChange_callsUseCaseAndSendsDelegate() async {
    let originalTemplate = createTemplate(title: "タイトル", content: "オリジナル内容")
    let updatedContentString = "更新された内容"
    let updatedTemplate = createTemplate(id: originalTemplate.id, title: "タイトル", content: updatedContentString)
    var dismissCalled = false

    var initialState = Feature.State(template: originalTemplate)
    initialState.content = NSAttributedString(string: updatedContentString)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.update = { template, newTitle, newContent in
        let expectedContent = NSAttributedString(string: updatedContentString)
        #expect(template == originalTemplate)
        #expect(newTitle == "タイトル")
        #expect(newContent == expectedContent)
        return updatedTemplate
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateTemplate(updatedTemplate)))

    #expect(dismissCalled)
    await store.finish()
  }

  //TODO: NSAttributedStringの等価比較が難しいため、一旦コメントアウト 編集されたかをどうかの判定ロジックをテスト用に追加する必要がある
  //  @Test @MainActor
  //  func testSave_withoutChange_onlyCallsDismiss() async {
  //    let template = createTemplate(title: "タイトル", content: "内容")
  //    var dismissCalled = false
  //    let useCaseWasCalled = LockIsolated<Bool>(false)
  //
  //    let store = TestStore(initialState: Feature.State(template: template)) {
  //      Feature()
  //    } withDependencies: {
  //      $0.templateUseCase.update = { _, _, _ in
  //        useCaseWasCalled.setValue(true)
  //        return template
  //      }
  //      $0.dismiss = DismissEffect {
  //        dismissCalled = true
  //      }
  //    }
  //
  //    await store.send(.internal(.save))
  //    await store.receive(.delegate(.updateTemplate(template)))
  //
  //    #expect(useCaseWasCalled.value)
  //    #expect(dismissCalled)
  //    await store.finish()
  //  }

  @Test @MainActor
  func testSave_onFailure_reportsError() async {
    let template = createTemplate()
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    var initialState = Feature.State(template: template)
    initialState.title = "更新されたタイトル"

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.update = { _, _, _ in
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
    let template = createTemplate()
    let store = TestStore(initialState: Feature.State(template: template)) {
      Feature()
    }

    await store.send(.view(.onAppear))
    await store.finish()
  }

  @Test @MainActor
  func testSaveButtonTapped_triggersSaveInternalAction() async {
    let template = createTemplate()
    let store = TestStore(initialState: Feature.State(template: template)) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.update = { template, newTitle, newContent in
        return template
      }
    }

    await store.send(.view(.saveButtonTapped))
    await store.receive(.internal(.save))
    await store.receive(.delegate(.updateTemplate(template)))
    await store.finish()
  }

  @Test @MainActor
  func testBackButtonTapped_callsDismiss() async {
    let template = createTemplate()
    var dismissCalled = false

    let store = TestStore(initialState: Feature.State(template: template)) {
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
    let template = createTemplate()
    let store = TestStore(initialState: Feature.State(template: template)) {
      Feature()
    }

    await store.send(.binding(.set(\.title, "新しいタイトル"))) {
      $0.title = "新しいタイトル"
    }
    await store.finish()
  }

  // TODO: NSAttributedStringの等価比較が難しいため、一旦コメントアウト
  //  @Test @MainActor
  //  func testBinding_updatesContent() async {
  //    let template = createTemplate()
  //    let newContent = NSAttributedString(string: "新しいコンテンツ") as @unchecked Sendable
  //    let store = TestStore(initialState: Feature.State(template: template)) {
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
    let updatedTemplate = createTemplate(id: template.id, title: "更新済み")

    let store = TestStore(initialState: Feature.State(template: template)) {
      Feature()
    }

    await store.send(.delegate(.updateTemplate(updatedTemplate)))
    await store.finish()
  }

  // MARK: - 複合テスト

  @Test @MainActor
  func testSave_withBothTitleAndContentChange_callsUseCaseAndSendsDelegate() async {
    let originalTemplate = createTemplate(title: "オリジナル", content: "オリジナル内容")
    let updatedTitle = "更新されたタイトル"
    let updatedContentString = "更新された内容"
    let updatedTemplate = createTemplate(id: originalTemplate.id, title: updatedTitle, content: updatedContentString)
    var dismissCalled = false

    var initialState = Feature.State(template: originalTemplate)
    initialState.title = updatedTitle
    initialState.content = NSAttributedString(string: updatedContentString)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.update = { template, newTitle, newContent in
        let expectedContent = NSAttributedString(string: updatedContentString)
        #expect(template == originalTemplate)
        #expect(newTitle == updatedTitle)
        #expect(newContent == expectedContent)
        return updatedTemplate
      }
      $0.dismiss = DismissEffect {
        dismissCalled = true
      }
    }

    await store.send(.internal(.save))
    await store.receive(.delegate(.updateTemplate(updatedTemplate)))

    #expect(dismissCalled)
    await store.finish()
  }
}
