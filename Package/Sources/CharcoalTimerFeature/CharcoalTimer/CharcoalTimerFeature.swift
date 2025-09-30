//
//  CharcoalTimerFeature.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/04.
//

import Common
import ComposableArchitecture
import Domain
import Extension
import Foundation
import SettingFeature

/// タイマー一覧画面
@Reducer
public struct CharcoalTimerFeature: Sendable {
  public typealias Timer = Domain.Timer
  public init() {}

  /// charcoalTimerUseCase
  @Dependency(\.timerUseCase) var timerUseCase
  /// errorHandler
  @Dependency(\.errorHandler) var errorHandler

  @ObservableState
  public struct State: Equatable {
    public init() {}
    /// すべてのタイマーが格納されている配列
    var timerList: [Timer] = []
    /// タイマー再描画させるためのフラグ
    public var isTimerUpdate: Bool = false
    /// ページネーション用のnextToken
    var nextToken: String?
    /// ページネーション読み込み中フラグ
    var isLoadingMore: Bool = false
    /// 画面遷移のState
    @Presents var destination: Destination.State?
  }

  public enum Action: ViewAction, Equatable {
    /// Viewからのアクション
    case view(ViewAction)
    /// Reducerからのアクション
    case `internal`(InternalAction)
    /// 子画面のアクション
    case destination(PresentationAction<Destination.Action>)

    public enum ViewAction: Equatable {
      /// 初期表示
      case onAppear
      /// さらに読み込み
      case loadMore
      /// チェックボタンタップ
      case checkButtonTapped(Timer)
      /// タイマー編集をタップ
      case timerTapped(Timer)
      /// 追加ボタンタップ
      case addButtonTapped
      /// リストスワイプで削除
      case swipeToDelete(Timer)
      /// セッティングをタップ
      case settingButtonTapped
    }

    public enum InternalAction: Equatable {
      /// タイマー取得
      case fetchTimer
      /// タイマー取得レスポンス
      case fetchTimerResponse([Timer])
      /// さらにタイマー取得実行
      case fetchMoreTimer
      /// さらにタイマー取得レスポンス
      case fetchMoreTimerResponse([Timer], String?)
      /// nextTokenセット
      case setNextToken(String)
      /// タイマースタート
      case startTimer
      /// タイマー更新
      case timerTick
      /// タイマーストップ
      case stopTimer
      // ステートの配列にタイマーを追加
      case addTimer(Timer)
      // ステートの配列からタイマーを更新
      case updateTimer(Timer)
      // ステートの配列からタイマーを削除
      case deleteTimer(Timer)
      /// エラーハンドリング
      case handleError(ErrorInfo)
    }
  }

  // タスクキャンセル用のID
  enum CancelID {
    // タイマー
    case timer
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        switch viewAction {
        case .onAppear:
          return .concatenate(
            .send(.internal(.fetchTimer)),
            .send(.internal(.startTimer))
          )

        case .loadMore:
          guard state.nextToken != nil, !state.isLoadingMore else {
            return .none
          }
          state.isLoadingMore = true
          return .send(.internal(.fetchMoreTimer))

        case .checkButtonTapped(let timer):
          return .run(
            operation: { send in
              // タイマーリセット
              let result = try await timerUseCase.reset(timer)
              await send(.internal(.updateTimer(result)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .timerTapped(let timer):
          state.destination = .editCharcoalTimer(.init(timer: timer))
          return .none

        case .addButtonTapped:
          state.destination = .addCharcoalTimer(.init())
          return .none

        case .swipeToDelete(let timer):
          return .run(
            operation: { send in
              try await timerUseCase.delete(timer)
              await send(.internal(.deleteTimer(timer)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .settingButtonTapped:
          state.destination = .settingMenu(.init())
          return .none
        }

      case .internal(let internalAction):
        switch internalAction {
        case .fetchTimer:
          state.nextToken = nil
          state.isLoadingMore = false
          return .run(
            operation: { send in
              // ページネーション対応でタイマー取得
              let result = try await timerUseCase.fetch(limit: 20)
              await send(.internal(.fetchTimerResponse(result.items)))
              if let nextToken = result.nextToken {
                await send(.internal(.setNextToken(nextToken)))
              }
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .fetchTimerResponse(let result):
          state.timerList = result
          // タイマー更新用フラグを変化させる
          state.isTimerUpdate.toggle()
          return .none

        case .fetchMoreTimer:
          guard let nextToken = state.nextToken else {
            state.isLoadingMore = false
            return .none
          }
          return .run(
            operation: { send in
              // 追加のタイマー取得
              let result = try await timerUseCase.fetchMore(nextToken: nextToken, limit: 20)
              await send(.internal(.fetchMoreTimerResponse(result.items, result.nextToken)))
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )

        case .fetchMoreTimerResponse(let moreTimers, let nextToken):
          state.isLoadingMore = false
          state.timerList.append(contentsOf: moreTimers)
          state.nextToken = nextToken
          // タイマーリストを再ソート
          state.timerList.sort {
            $0.nextCheckTime < $1.nextCheckTime
          }
          return .none

        case .setNextToken(let token):
          state.nextToken = token
          return .none

        case .startTimer:
          return .run(
            operation: { send in
              // 60秒ごとに繰り返す処理
              while true {
                try await Task.sleep(for: .seconds(0.5))
                await send(.internal(.timerTick))
              }
            },
            catch: { error, send in
              let errorInfo = error.toErrorInfo()
              await send(.internal(.handleError(errorInfo)))
            }
          )
          .cancellable(
            id: CancelID.timer,
            cancelInFlight: true
          )

        case .timerTick:
          // タイマー更新用フラグを変化させる
          state.isTimerUpdate.toggle()
          return .none

        case .stopTimer:
          return .cancel(id: CancelID.timer)

        case .addTimer(let timer):
          // タイマーを追加
          state.timerList.append(timer)
          // nexrtCheckTimeの近い順に上から表示するように並び替え
          state.timerList.sort {
            $0.nextCheckTime < $1.nextCheckTime
          }
          return .none

        case .updateTimer(let timer):
          if let index = state.timerList.firstIndex(where: { $0.id == timer.id }) {
            // タイマーを更新したものと置き換え
            state.timerList[index] = timer
            // nexrtCheckTimeの近い順に上から表示するように並び替え
            state.timerList.sort {
              $0.nextCheckTime < $1.nextCheckTime
            }
          }
          return .none

        case .deleteTimer(let timer):
          if let index = state.timerList.firstIndex(where: { $0.id == timer.id }) {
            // タイマーを削除
            state.timerList.remove(at: index)
          }
          return .none

        case .handleError(let errorInfo):
          // エラーハンドラーに送信
          errorHandler.send(errorInfo)
          return .none
        }

      case .destination(.presented(.addCharcoalTimer(.delegate(.addTimer(let timer))))):
        return .send(.internal(.addTimer(timer)))

      case .destination(.presented(.editCharcoalTimer(.delegate(.updateTimer(let timer))))):
        return .send(.internal(.updateTimer(timer)))

      case .destination(.dismiss):
        return .send(.internal(.fetchTimer))

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension CharcoalTimerFeature {
  @Reducer(state: .equatable, action: .equatable)
  public enum Destination {
    // タイマー追加画面
    case addCharcoalTimer(AddCharcoalTimerFeature)
    // タイマー編集画面
    case editCharcoalTimer(EditCharcoalTimerFeature)
    // 設定メニュー画面
    case settingMenu(SettingMenuFeature)
  }
}
