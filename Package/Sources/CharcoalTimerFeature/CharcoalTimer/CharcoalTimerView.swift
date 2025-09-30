//
//  CharcoalTimerView.swift
//  Package
//
//  Created by Yutaka Inoue on 2024/10/04.
//

import Common
import ComposableArchitecture
import Domain
import SettingFeature
import SwiftUI

@ViewAction(for: CharcoalTimerFeature.self)
public struct CharcoalTimerView: View {
  typealias Timer = Domain.Timer
  @Bindable public var store: StoreOf<CharcoalTimerFeature>

  public init(store: StoreOf<CharcoalTimerFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      List {
        ForEach(store.timerList) { timer in
          VStack {
            TimerItemView(
              timer,
              isTimerUpdate: store.isTimerUpdate
            ) {
              send(.checkButtonTapped(timer))
            } timerTapped: {
              send(.timerTapped(timer))
            }
            .swipeActions {
              Button {
                send(.swipeToDelete(timer))
              } label: {
                Image(systemName: "trash")
              }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .onAppear {
              // 最後から3番目のアイテムが表示されたら次のページを読み込み
              if let lastTimer = store.timerList.dropLast(2).last,
                timer.id == lastTimer.id,
                store.nextToken != nil,
                !store.isLoadingMore
              {
                send(.loadMore)
              }
            }
          }
        }
        .listRowBackground(Color.appPrimary)

        // ローディングインジケーター
        if store.isLoadingMore {
          HStack {
            Spacer()
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(1.2)
            Spacer()
          }
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .frame(height: 60)
        }

        // フッター余白
        Spacer()
          .frame(height: 100)
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
      }
      .listRowSpacing(8)
      .animation(.default, value: store.timerList)
      .scrollContentBackground(.hidden)
      .background(Color.primaryBackground)

      FloatingButton {
        send(.addButtonTapped)
      }
    }
    .onAppear {
      send(.onAppear)
    }
    .navigationBarItem(
      placement: .topBarTrailing,
      content: {
        Image(systemName: "gearshape")
          .foregroundColor(.appPrimary)
      },
      action: {
        send(.settingButtonTapped)
      }
    )
    .navigationTitle("タイマー")
    .sheet(
      item: $store.scope(
        state: \.destination?.addCharcoalTimer,
        action: \.destination.addCharcoalTimer
      )
    ) { store in
      AddCharcoalTimerView(store: store)
        .presentationDetents([.height(300)])
    }
    .sheet(
      item: $store.scope(
        state: \.destination?.editCharcoalTimer,
        action: \.destination.editCharcoalTimer
      )
    ) { store in
      EditCharcoalTimerView(store: store)
        .presentationDetents([.height(300)])
    }
    .fullScreenCover(
      item: $store.scope(
        state: \.destination?.settingMenu,
        action: \.destination.settingMenu
      )
    ) { store in
      SettingMenuView(store: store)
    }
  }

  private struct TimerItemView: View {
    public init(
      _ timer: Timer,
      isTimerUpdate: Bool,
      checkButtonTapped: @escaping () -> Void,
      timerTapped: @escaping () -> Void
    ) {
      self.timer = timer
      self.isTimerUpdate = isTimerUpdate
      self.checkButtonTapped = checkButtonTapped
      self.timerTapped = timerTapped
    }

    let timer: Timer
    let isTimerUpdate: Bool
    @State var tableName: String = ""
    @State var remindMinutes: Int = 0
    @State var isCheckRequest: Bool = false
    let checkButtonTapped: () -> Void
    let timerTapped: () -> Void

    // タイマーの状態による色とアイコン
    private var timerState: TimerState {
      if isCheckRequest {
        return .urgent
      } else if remindMinutes <= 5 {
        return .warning
      } else {
        return .normal
      }
    }

    public var body: some View {
      Button {
        timerTapped()
      } label: {
        HStack(spacing: 12) {
          // 状態インジケーター
          VStack(spacing: 4) {
            Image(systemName: timerState.iconName)
              .font(.system(size: 20, weight: .medium))
              .foregroundColor(.white)
              .frame(width: 32, height: 32)
              .background(
                Circle()
                  .fill(timerState.accentColor)
              )
          }

          // メインコンテンツ
          VStack(alignment: .leading, spacing: 6) {
            // テーブル名
            Text(tableName.isEmpty ? "読み込み中..." : tableName)
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.white)
              .lineLimit(1)

            // 時間表示とステータス
            HStack(spacing: 8) {
              if isCheckRequest {
                Text("確認が必要です")
                  .font(.system(size: 14, weight: .medium))
                  .foregroundColor(.white)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(
                    Capsule()
                      .fill(timerState.accentColor)
                  )
              } else {
                Text("\(formatTime(remindMinutes))後")
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(.white.opacity(0.9))
              }

              Spacer()

            }
          }

          Spacer()

          // アクションボタン
          if isCheckRequest {
            Button(action: checkButtonTapped) {
              HStack(spacing: 6) {
                Image(systemName: "checkmark")
                  .font(.system(size: 14, weight: .semibold))
                Text("確認")
                  .font(.system(size: 14, weight: .semibold))
              }
              .foregroundColor(.white)
              .padding(.vertical, 10)
              .padding(.horizontal, 16)
              .background(
                RoundedRectangle(cornerRadius: 20)
                  .fill(timerState.accentColor)
              )
            }
            .buttonStyle(.plain)
          } else {
            Image(systemName: "chevron.right")
              .font(.system(size: 14))
              .foregroundColor(.white.opacity(0.4))
          }
        }
        .padding(.vertical, 10)
      }
      .buttonStyle(.plain)
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isCheckRequest)
      .onAppear {
        updateTimeValues()
        loadTableName()
      }
      .onChange(of: isTimerUpdate) {
        updateTimeValues()
        loadTableName()
      }
    }

    private func updateTimeValues() {
      let newRemindMinutes = timer.nextCheckTime.foundationDate.minutesUntilNow
      let newIsCheckRequest = newRemindMinutes <= 0

      remindMinutes = newRemindMinutes
      isCheckRequest = newIsCheckRequest
    }

    private func loadTableName() {
      Task {
        do {
          tableName = try await timer.table?.name ?? "不明なテーブル"
        } catch {
          tableName = "不明なテーブル"
        }
      }
    }

    private func formatTime(_ minutes: Int) -> String {
      if minutes >= 60 {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes > 0 {
          return "\(hours)時間\(remainingMinutes)分"
        } else {
          return "\(hours)時間"
        }
      } else {
        return "\(minutes)分"
      }
    }
  }

  // タイマーの状態を表すenum
  private enum TimerState {
    case normal
    case warning
    case urgent

    var iconName: String {
      switch self {
      case .normal:
        return "timer"
      case .warning:
        return "clock.badge.exclamationmark"
      case .urgent:
        return "bell.fill"
      }
    }

    var accentColor: Color {
      switch self {
      case .normal:
        return .blue
      case .warning:
        return .orange
      case .urgent:
        return .red
      }
    }

  }
}

#Preview {
  CharcoalTimerView(
    store: .init(initialState: .init()) {
      CharcoalTimerFeature()
    }
  )
}
