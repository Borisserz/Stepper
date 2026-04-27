//
//  AICoachChatView.swift
//  Stepper
//
//  Real chat surface backed by `AICoachService` (FirebaseAI / Vertex
//  Gemini 2.5 Flash). Lives inside the existing `AICoreHubView` as the
//  first tab. Until the user adds the FirebaseAI SPM package, the service
//  returns an offline fallback and the UI gracefully shows it.
//

import SwiftUI

struct AICoachChatView: View {
    @State private var coach = AICoachService.shared
    @State private var draft: String = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            transcript
            composer
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Transcript

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 12) {
                    if coach.transcript.isEmpty {
                        emptyState
                    }
                    ForEach(coach.transcript) { turn in
                        TurnRow(turn: turn)
                            .id(turn.id)
                    }
                    if coach.isThinking {
                        thinkingBubble
                            .id("__thinking")
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: coach.transcript.count) { _, _ in
                withAnimation {
                    if let last = coach.transcript.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: coach.isThinking) { _, thinking in
                if thinking { withAnimation { proxy.scrollTo("__thinking", anchor: .bottom) } }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.accentCyan)
            Text("ai.coach.empty.title")
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text("ai.coach.empty.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            HStack(spacing: 8) {
                ForEach(Self.suggestions, id: \.self) { suggestion in
                    Button {
                        draft = suggestion
                        send()
                    } label: {
                        Text(suggestion)
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 24)
    }

    private var thinkingBubble: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(AppTheme.accentCyan)
                    .frame(width: 6, height: 6)
                    .opacity(0.4)
                    .scaleEffect(coach.isThinking ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.2), value: coach.isThinking)
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }

    // MARK: - Composer

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("ai.coach.placeholder", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(.white)
                .focused($inputFocused)

            Button {
                send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? AppTheme.accentCyan : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.bottom, 12)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !coach.isThinking
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        inputFocused = false
        Task { await coach.ask(text) }
    }

    private static let suggestions: [String] = [
        "Какая у меня форма?",
        "Что съесть после пробежки?",
        "Как восстановиться?"
    ]
}

private struct TurnRow: View {
    let turn: AICoachService.Turn

    var body: some View {
        HStack(alignment: .bottom) {
            if turn.role == .user { Spacer(minLength: 24) }

            Text(turn.text)
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    turn.role == .user
                    ? AnyShapeStyle(LinearGradient(colors: [AppTheme.accentCyan.opacity(0.9), AppTheme.accentBlue.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyShapeStyle(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                )

            if turn.role == .assistant { Spacer(minLength: 24) }
        }
        .padding(.horizontal, 8)
    }
}
