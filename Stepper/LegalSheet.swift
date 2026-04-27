//
//  LegalSheet.swift
//  Stepper
//
//  Renders the static legal documents (Privacy Policy, Terms of Service,
//  Support) inside the app via a Markdown view. The hosted GitHub Pages
//  versions (https://borisserz.github.io/Stepper/...) remain authoritative
//  for App Store Connect; the in-app copy is a convenience for users who
//  open Settings → Legal without a network connection.
//

import SwiftUI

enum LegalSheetKind: String, Identifiable {
    case privacy
    case terms
    case support

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .privacy: return "settings.legal.privacyPolicy"
        case .terms: return "settings.legal.termsOfService"
        case .support: return "settings.legal.support"
        }
    }

    var fallbackResource: String {
        switch self {
        case .privacy: return "privacy-policy"
        case .terms: return "terms-of-service"
        case .support: return "support"
        }
    }

    var hostedURL: URL? {
        let path: String
        switch self {
        case .privacy: path = "privacy-policy.html"
        case .terms: path = "terms-of-service.html"
        case .support: path = "support.html"
        }
        return URL(string: "https://borisserz.github.io/Stepper/\(path)")
    }
}

struct LegalSheet: View {
    let kind: LegalSheetKind
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(Text(kind.titleKey))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let url = kind.hostedURL {
                        Button {
                            openURL(url)
                        } label: {
                            Image(systemName: "safari")
                        }
                        .accessibilityLabel(Text("legal.openInBrowser"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    /// Loads the bundled `<resource>.md` if present, otherwise renders a
    /// short placeholder pointing to the hosted version.
    private var content: AttributedString {
        if let url = Bundle.main.url(forResource: kind.fallbackResource, withExtension: "md"),
           let raw = try? String(contentsOf: url, encoding: .utf8),
           let attributed = try? AttributedString(markdown: raw,
                                                  options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributed
        }
        let fallback = String(
            format: NSLocalizedString("legal.fallback",
                                      value: "Read the latest version at %@.",
                                      comment: ""),
            kind.hostedURL?.absoluteString ?? "https://borisserz.github.io/Stepper/"
        )
        return AttributedString(fallback)
    }
}
