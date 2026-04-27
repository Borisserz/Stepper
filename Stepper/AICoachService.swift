//
//  AICoachService.swift
//  Stepper
//
//  Real AI Coach backed by Vertex AI Gemini through the Firebase AI Logic
//  SDK (FirebaseAI). Replaces the mock responses inside `AICoreViews`.
//
//  Why FirebaseAI and not OpenAI / Anthropic / a Cloud Function:
//   - service account credentials never leave Google's network.
//   - App Check (DeviceCheck on prod, Debug provider on simulator) gates
//     every call so a stolen GoogleService-Info.plist can't be abused.
//   - billing is on the user's own Vertex project; no Cognition relay.
//
//  Wrapped in `#if canImport(FirebaseAI)` so the project keeps compiling
//  before the SPM package is added.
//

import Foundation

#if canImport(FirebaseAI)
import FirebaseAI
#endif

@MainActor
@Observable
final class AICoachService {
    static let shared = AICoachService()
    private init() {}

    /// Last few exchanges so the model has continuity inside a session.
    /// Cleared when the user opens a new conversation. Capped at 12 turns
    /// to stay well below the 1M token context window for `gemini-2.5-flash`.
    private(set) var transcript: [Turn] = []

    /// True while a request is in flight. Drives the typing indicator in
    /// `AICoreHubView`.
    private(set) var isThinking: Bool = false

    var lastError: String?

    /// Sends a user message; returns the assistant reply (also appended to
    /// `transcript`). When Firebase AI isn't configured, falls back to a
    /// canned offline response so the UI is never broken.
    @discardableResult
    func ask(_ prompt: String) async -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        transcript.append(.init(role: .user, text: trimmed))

        let reply = await sendThroughFirebaseAI(history: transcript)
        transcript.append(.init(role: .assistant, text: reply))

        // Trim oldest pairs once we exceed the soft cap.
        if transcript.count > 24 { transcript.removeFirst(transcript.count - 24) }
        return reply
    }

    func resetConversation() {
        transcript.removeAll()
        lastError = nil
    }

    // MARK: - Backend

    private func sendThroughFirebaseAI(history: [Turn]) async -> String {
        #if canImport(FirebaseAI)
        guard FirebaseBootstrap.isConfigured else {
            return Self.offlineFallback
        }
        isThinking = true
        defer { isThinking = false }

        let ai = FirebaseAI.firebaseAI(backend: .vertexAI())
        let model = ai.generativeModel(
            modelName: "gemini-2.5-flash",
            systemInstruction: ModelContent(role: "system", parts: [TextPart(Self.systemPrompt)]) )

        // Map our local transcript into Firebase AI ModelContent.
        let contents: [ModelContent] = history.map { turn in
            let role = turn.role == .user ? "user" : "model"
    
            return ModelContent(role: role, parts: [TextPart(turn.text)])
       }

        do {
            let response = try await model.generateContent(contents)
            let text = response.text ?? ""
            if text.isEmpty {
                lastError = "Empty response"
                return Self.offlineFallback
            }
            lastError = nil
            return text
        } catch {
            lastError = error.localizedDescription
            return Self.offlineFallback
        }
        #else
        _ = history
        return Self.offlineFallback
        #endif
    }

    // MARK: - Prompts & fallbacks

    private static let systemPrompt = """
    You are footstepeR's AI Kinetic Core — an in-app fitness coach for runners
    and walkers. Be concise (2-4 sentences max), motivating, and specific.
    Reply in the same language as the user. Never invent metrics that the
    user didn't share. Refuse anything unrelated to fitness, recovery,
    nutrition, or running form. Never give medical advice — defer to a
    professional for injuries.
    """

    private static let offlineFallback = "AI Coach пока недоступен — попробуй позже."

    // MARK: - Types

    struct Turn: Identifiable, Equatable {
        let id = UUID()
        let role: Role
        let text: String

        enum Role { case user, assistant }
    }
}
