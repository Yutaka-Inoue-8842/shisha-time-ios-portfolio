//
//  TemplateListFeatureTests.swift
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
struct TemplateListFeatureTests {
  typealias Feature = TemplateListFeature
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
  func testFetchAllTemplateResponse_setsListAndIsLoaded() async {
    let templates = [
      createTemplate(),
      createTemplate()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.fetchAllTemplateResponse(templates))) {
      $0.isLoaded = true
      $0.templateList = templates
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddTemplate_insertsAtTop() async {
    let template = createTemplate()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.internal(.addTemplate(template))) {
      $0.templateList = [template]
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddTemplate_insertsAtTopOfExistingList() async {
    let existingTemplate = createTemplate(title: "既存テンプレート")
    let newTemplate = createTemplate(title: "新しいテンプレート")

    var initialState = Feature.State()
    initialState.templateList = [existingTemplate]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.addTemplate(newTemplate))) {
      $0.templateList = [newTemplate, existingTemplate]
    }
    await store.finish()
  }

  @Test @MainActor
  func testUpdateTemplate_removesOldAndInsertsAtTop() async {
    let id = UUID().uuidString
    let beforeTemplate = createTemplate(id: id, title: "Before")
    let afterTemplate = createTemplate(id: id, title: "After")
    let otherTemplate = createTemplate(title: "Other")

    var initialState = Feature.State()
    initialState.templateList = [otherTemplate, beforeTemplate]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateTemplate(afterTemplate))) {
      $0.templateList = [afterTemplate, otherTemplate]
    }
    await store.finish()
  }

  @Test @MainActor
  func testDeleteTemplate_removesMatchedItem() async {
    let templates = [
      createTemplate(),
      createTemplate()
    ]
    var initialState = Feature.State()
    initialState.templateList = templates

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteTemplate(templates[0]))) {
      $0.templateList = [templates[1]]
    }
    await store.finish()
  }

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

  // MARK: - Viewアクション

  @Test @MainActor
  func testOnAppear_fetchesAllAndSetsList() async {
    let templates = [
      createTemplate(),
      createTemplate()
    ]

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.fetchAll = {
        templates
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.fetchAllTemplateResponse(templates))) {
      $0.isLoaded = true
      $0.templateList = templates
    }
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_whenAlreadyLoaded_doesNothing() async {
    var initialState = Feature.State()
    initialState.isLoaded = true

    let useCaseWasCalled = LockIsolated<Bool>(false)

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.fetchAll = {
        useCaseWasCalled.setValue(true)
        return []
      }
    }

    await store.send(.view(.onAppear))

    #expect(!useCaseWasCalled.value)
    await store.finish()
  }

  @Test @MainActor
  func testOnAppear_onFailure_reportsError() async {
    let error = AppError.unknown
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.fetchAll = {
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.onAppear))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  @Test @MainActor
  func testTemplateTapped_presentsEditScreenWithTemplate() async {
    let template = createTemplate()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.templateTapped(template))) {
      $0.destination = .editTemplate(.init(template: template))
    }
    await store.finish()
  }

  @Test @MainActor
  func testAddButtonTapped_presentsAddScreen() async {
    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addTemplate(.init())
    }
    await store.finish()
  }

  @Test @MainActor
  func testSwipeToDelete_callsUseCaseAndRemovesOnSuccess() async {
    let template = createTemplate()
    let deletedTemplate = LockIsolated<Template?>(nil)
    var initialState = Feature.State()
    initialState.templateList = [template]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.delete = { template in
        deletedTemplate.setValue(template)
      }
    }

    await store.send(.view(.swipeToDelete(template)))
    await store.receive(.internal(.deleteTemplate(template))) {
      $0.templateList = []
    }

    #expect(deletedTemplate.value == template)
    await store.finish()
  }

  @Test @MainActor
  func testSwipeToDelete_onFailure_reportsErrorAndKeepsState() async {
    let error = AppError.unknown
    let template = createTemplate()
    let sentErrorInfo = LockIsolated<ErrorInfo?>(nil)
    var initialState = Feature.State()
    initialState.templateList = [template]

    let store = TestStore(initialState: initialState) {
      Feature()
    } withDependencies: {
      $0.templateUseCase.delete = { _ in
        throw error
      }
      $0.errorHandler.send = { errorInfo in
        sentErrorInfo.setValue(errorInfo)
      }
    }

    await store.send(.view(.swipeToDelete(template)))
    await store.receive(.internal(.handleError(error.toErrorInfo())))

    #expect(store.state.templateList == [template])
    #expect(sentErrorInfo.value == error.toErrorInfo())
    await store.finish()
  }

  // MARK: - 子画面 delegate → 親のinternalに変換されること（タイムラグあり）

  @Test @MainActor
  func testAddTemplateDelegate_flowsToInternalAddWithDelay() async {
    let template = createTemplate()

    let store = TestStore(initialState: Feature.State()) {
      Feature()
    }

    // まず destination を設定
    await store.send(.view(.addButtonTapped)) {
      $0.destination = .addTemplate(.init())
    }

    // その後で delegate アクションを送信
    await store.send(.destination(.presented(.addTemplate(.delegate(.addTemplate(template))))))
    await store.receive(.internal(.addTemplate(template)), timeout: .seconds(1)) {
      $0.templateList = [template]
    }
    await store.finish()
  }

  @Test @MainActor
  func testEditTemplateDelegate_flowsToInternalUpdateWithDelay() async {
    let id = UUID().uuidString
    let beforeTemplate = createTemplate(id: id, title: "Before")
    let afterTemplate = createTemplate(id: id, title: "After")
    var initialState = Feature.State()
    initialState.templateList = [beforeTemplate]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.view(.templateTapped(beforeTemplate))) {
      $0.destination = .editTemplate(.init(template: beforeTemplate))
    }

    await store.send(.destination(.presented(.editTemplate(.delegate(.updateTemplate(afterTemplate))))))
    await store.receive(.internal(.updateTemplate(afterTemplate)), timeout: .seconds(1)) {
      $0.templateList = [afterTemplate]
    }
    await store.finish()
  }

  // MARK: - エッジケース

  @Test @MainActor
  func testUpdateTemplate_whenItemNotFound_keepsOriginalState() async {
    let templates = [
      createTemplate(),
      createTemplate()
    ]
    var initialState = Feature.State()
    initialState.templateList = [templates[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.updateTemplate(templates[1])))
    await store.finish()
  }

  @Test @MainActor
  func testDeleteTemplate_whenItemNotFound_keepsOriginalState() async {
    let templates = [
      createTemplate(),
      createTemplate()
    ]
    var initialState = Feature.State()
    initialState.templateList = [templates[0]]

    let store = TestStore(initialState: initialState) {
      Feature()
    }

    await store.send(.internal(.deleteTemplate(templates[1])))
    await store.finish()
  }
}
