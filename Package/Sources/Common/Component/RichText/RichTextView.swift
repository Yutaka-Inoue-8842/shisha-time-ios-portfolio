//
//  RichTextView.swift
//  Package
//
//  Created by Yutaka Inoue on 2025/02/27.
//

import Extension
import SwiftUI

#if canImport(UIKit)
  import UIKit
#endif

public struct RichTextView: UIViewRepresentable {
  public init(
    content: Binding<NSAttributedString>
  ) {
    self._content = content
  }
  @Binding var content: NSAttributedString
  private let textView: UITextView = UITextView()

  public func makeUIView(context: Context) -> UITextView {
    textView.isEditable = true
    textView.isScrollEnabled = true
    textView.dataDetectorTypes = [.phoneNumber, .link]
    textView.backgroundColor = .clear
    textView.autocorrectionType = .no
    textView.delegate = context.coordinator
    textView.attributedText = content
    textView.inputAccessoryView = context.coordinator.createToolbar()
    textView.typingAttributes = RichTextHelper.getTextStyleAttribute(.body)
    return textView
  }

  public func updateUIView(_ uiView: UITextView, context: Context) {
    uiView.attributedText = content
  }

  public func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  public class Coordinator: NSObject, UITextViewDelegate {
    var parent: RichTextView

    /// タイトルスタイル適用ボタン
    private lazy var titleButton: UIButton = {
      let button = UIButton(type: .system)
      button.setImage(.titleTextUnselect, for: .normal)
      button.addTarget(self, action: #selector(applyTitle), for: .touchUpInside)
      return button
    }()

    /// 見出しスタイル適用ボタン
    private lazy var headlineButton: UIButton = {
      let button = UIButton(type: .system)
      button.setImage(.headlineTextUnselect, for: .normal)
      button.addTarget(self, action: #selector(applyHeadline), for: .touchUpInside)
      return button
    }()
    /// 本文スタイル適用ボタン
    private lazy var bodyButton: UIButton = {
      let button = UIButton(type: .system)
      button.setImage(.bodyTextUnselect, for: .normal)
      button.addTarget(self, action: #selector(applyBody), for: .touchUpInside)
      return button
    }()

    /// 箇条書スタイル適用ボタン
    private lazy var bulletButton: UIButton = {
      let button = UIButton(type: .system)
      button.setImage(.bulletTextUnselect, for: .normal)
      button.addTarget(self, action: #selector(applyBullet), for: .touchUpInside)
      return button
    }()

    init(_ parent: RichTextView) {
      self.parent = parent
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
      updateToolbarButtonStates()
    }

    public func textViewDidChange(_ textView: UITextView) {

      // textViewのattributedTextを変更可能に
      let attributedText = NSMutableAttributedString(attributedString: parent.textView.attributedText)

      // 1行目の文字が入力された場合、titleスタイルを適用
      let fullText = attributedText.string
      let lines = fullText.components(separatedBy: .newlines)
      if lines.count == 1 && !lines[0].isEmpty && parent.content.string.isEmpty {
        // 初回入力時（空から文字が入力された場合）
        let currentSelection = parent.textView.selectedRange
        applyStyle(.title)
        parent.textView.selectedRange = currentSelection
        return
      }

      // 直前の文字が存在しない場合は処理を終了
      guard parent.textView.selectedRange.location > 0 else {
        parent.content = attributedText
        return
      }

      // 直前の文字
      let textBeforeCursor = (attributedText.string as NSString).substring(
        with: NSRange(
          location: parent.textView.selectedRange.location - 1,
          length: 1
        )
      )
      // 変更直線の文字が改行コードであるか
      let isNewLine = textBeforeCursor == "\n"

      // 改行されていない場合は処理を終了
      guard isNewLine else {
        parent.content = attributedText
        return
      }

      // 以下改行がなされた場合の処理

      // 現在の行の範囲を取得
      guard
        let currentLineRange = RichTextHelper.getCurrentLineRange(
          attributedText: attributedText,
          selectedRange: parent.textView.selectedRange
        )
      else {
        return
      }

      //　現在の行に文字がない場合（空行の場合）フォントをBodyに変更
      if currentLineRange.length == 0 {
        parent.textView.typingAttributes = RichTextHelper.getTextStyleAttribute(.body)
      }

      // 1行目が改行された場合、1行目を必ずtitleスタイルに変更
      let allLines = fullText.components(separatedBy: .newlines)
      if allLines.count >= 2 && !allLines[0].isEmpty {
        let firstLineRange = NSRange(location: 0, length: allLines[0].count)
        let firstLineStyle = RichTextHelper.getLineTextStyle(
          attributedText: attributedText,
          lineRange: firstLineRange
        )
        if firstLineStyle != .title {
          // 1行目をtitleスタイルに変更
          let currentSelection = parent.textView.selectedRange
          let updatedAttributedText = RichTextHelper.toggleTitleStyle(
            attributedText: attributedText,
            range: firstLineRange,
            currentStyle: firstLineStyle
          )
          parent.content = updatedAttributedText
          parent.textView.attributedText = updatedAttributedText
          parent.textView.selectedRange = currentSelection
        }
      }

      // 前の行の範囲を取得
      guard
        let beforeLineRange = RichTextHelper.getBeforeLineRange(
          attributedText: attributedText,
          selectedRange: parent.textView.selectedRange
        )
      else {
        return
      }

      // 前の行のスタイルを取得
      let beforeLineStyle = RichTextHelper.getLineTextStyle(
        attributedText: attributedText,
        lineRange: beforeLineRange
      )

      // 一つ前の行が箇条書きスタイル && 一つ前の行に文字がない場合（箇条書きの⚫︎は１文字とカウントされる）
      if beforeLineStyle == .bullet, beforeLineRange.length == 1 {
        // 改行を戻し箇条書きの⚫︎を消す
        attributedText.replaceCharacters(in: NSRange(location: beforeLineRange.location, length: 2), with: "")
        parent.content = attributedText
        parent.textView.attributedText = attributedText
        return
      }

      // 一つ前の行が箇条書きスタイル && 文字が増えている場合（バックスペースされた場合はfalseとしたい）
      if beforeLineStyle == .bullet, parent.content.length < parent.textView.attributedText.length {
        // 箇条書きスタイルを適用
        let currentSelection = parent.textView.selectedRange
        applyStyle(.bullet)
        // カーソル位置を箇条書きの点の後ろに移動
        parent.textView.selectedRange = NSRange(location: currentSelection.location + 1, length: 0)
        return
      }
    }

    func applyStyle(_ style: TextStyle) {
      let currentSelection = parent.textView.selectedRange

      var mutableAttributedString = NSMutableAttributedString(
        attributedString: parent.textView.attributedText
      )

      guard
        let lineRange = RichTextHelper.getCurrentLineRange(
          attributedText: mutableAttributedString,
          selectedRange: parent.textView.selectedRange
        )
      else {
        return
      }

      let currentStyle = RichTextHelper.getLineTextStyle(
        attributedText: mutableAttributedString,
        lineRange: lineRange
      )

      switch style {
      case .title:
        mutableAttributedString = RichTextHelper.toggleTitleStyle(
          attributedText: mutableAttributedString,
          range: lineRange,
          currentStyle: currentStyle
        )
      case .headline:
        mutableAttributedString = RichTextHelper.toggleHeadlineStyle(
          attributedText: mutableAttributedString,
          range: lineRange,
          currentStyle: currentStyle
        )
      case .body:
        mutableAttributedString = RichTextHelper.applyBodyStyle(
          attributedText: mutableAttributedString,
          range: lineRange,
          currentStyle: currentStyle
        )
      case .bullet:
        mutableAttributedString = RichTextHelper.toggleBulletStyle(
          attributedText: mutableAttributedString,
          range: lineRange,
          currentStyle: currentStyle
        )
      }

      parent.content = mutableAttributedString
      parent.textView.attributedText = mutableAttributedString
      parent.textView.selectedRange = currentSelection
      parent.textView.typingAttributes = RichTextHelper.getTextStyleAttribute(style)
      updateToolbarButtonStates()
    }

    @objc func applyTitle() {
      applyStyle(.title)
    }

    @objc func applyHeadline() {
      applyStyle(.headline)
    }

    @objc func applyBody() {
      applyStyle(.body)
    }

    @objc func applyBullet() {
      applyStyle(.bullet)
    }

    /// カスタムツールバーを作成
    func createToolbar() -> UIView {
      // コンテナ用View
      let container = UIView()
      container.backgroundColor = UIColor(Color.secondaryBackground)
      container.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)

      // ボタンを並べるStack
      let stackView = UIStackView()
      stackView.axis = .horizontal
      stackView.distribution = .equalSpacing
      stackView.alignment = .center
      stackView.spacing = 8

      // 表示するボタン
      let buttons: [UIButton] = [
        titleButton,
        headlineButton,
        bodyButton,
        bulletButton
      ]

      // 制約
      buttons.forEach {
        $0.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
          $0.widthAnchor.constraint(equalToConstant: 32),
          $0.heightAnchor.constraint(equalToConstant: 32)
        ])
        stackView.addArrangedSubview($0)
      }

      stackView.translatesAutoresizingMaskIntoConstraints = false
      container.addSubview(stackView)

      NSLayoutConstraint.activate([
        stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
        stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        stackView.heightAnchor.constraint(equalToConstant: 32),
        stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 6)
      ])

      return container
    }

    /// スタイルボタンの状態を更新する
    private func updateToolbarButtonStates() {
      let attributedText = NSMutableAttributedString(attributedString: parent.textView.attributedText)
      let selectedRange = parent.textView.selectedRange

      // 現在の行の範囲を取得
      guard
        let currentLineRange = RichTextHelper.getCurrentLineRange(
          attributedText: attributedText,
          selectedRange: selectedRange
        )
      else {
        return
      }

      // 現在の行のスタイルを取得
      let currentStyle = RichTextHelper.getLineTextStyle(
        attributedText: attributedText,
        lineRange: currentLineRange
      )

      titleButton.setImage(currentStyle == .title ? .titleTextSelect : .titleTextUnselect, for: .normal)
      headlineButton.setImage(currentStyle == .headline ? .headlineTextSelect : .headlineTextUnselect, for: .normal)
      bodyButton.setImage(currentStyle == .body ? .bodyTextSelect : .bodyTextUnselect, for: .normal)
      bulletButton.setImage(currentStyle == .bullet ? .bulletTextSelect : .bulletTextUnselect, for: .normal)
    }
  }
}
