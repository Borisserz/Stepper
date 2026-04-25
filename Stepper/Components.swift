import SwiftUI

struct MeshGradientBackground: View {
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            LinearGradient(colors: [AppTheme.accentPurple.opacity(0.15), .clear, AppTheme.accentBlue.opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        }.allowsHitTesting(false).drawingGroup()
    }
}

struct BouncyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.contentShape(Rectangle()).scaleEffect(configuration.isPressed ? 0.92 : 1.0).animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed).brightness(configuration.isPressed ? 0.2 : 0)
    }
}

struct BottomActionButton: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: { triggerImpact(); action() }) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundColor(color)
                Text(title).font(.caption.bold()).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.8)
            }.frame(maxWidth: .infinity).padding(.vertical, 15).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.3), lineWidth: 1))
        }.buttonStyle(BouncyButton())
    }
}

struct CyberToast: View {
    let message: String
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "info.circle.fill").foregroundColor(AppTheme.neonGreen).font(.title2)
            Text(message).font(.subheadline.bold()).foregroundColor(.white).multilineTextAlignment(.leading)
        }.padding(15).background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.neonGreen.opacity(0.5), lineWidth: 1)).shadow(color: AppTheme.neonGreen.opacity(0.3), radius: 15).padding(.horizontal, 20).padding(.top, 50).transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct FloatingParticlesView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { _ in
                Circle().fill(Color.white.opacity(Double.random(in: 0.1...0.3))).frame(width: CGFloat.random(in: 2...5)).position(x: CGFloat.random(in: 0...400), y: animate ? -50 : CGFloat.random(in: 500...1000)).animation(.linear(duration: Double.random(in: 8...15)).repeatForever(autoreverses: false).delay(Double.random(in: 0...5)), value: animate)
            }
        }.drawingGroup().onAppear { animate = true }.allowsHitTesting(false)
    }
}

struct CyberpunkRainView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { _ in
                Capsule().fill(LinearGradient(colors: [AppTheme.accentCyan.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top)).frame(width: 2, height: CGFloat.random(in: 10...30)).position(x: CGFloat.random(in: 0...400), y: animate ? 1000 : -100).animation(.linear(duration: Double.random(in: 0.5...1.5)).repeatForever(autoreverses: false).delay(Double.random(in: 0...2)), value: animate)
            }
        }.drawingGroup().onAppear { animate = true }.allowsHitTesting(false)
    }
}

struct CyberSnowView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            ForEach(0..<40, id: \.self) { _ in
                Circle().fill(Color.white.opacity(Double.random(in: 0.4...0.9))).frame(width: CGFloat.random(in: 2...6)).position(x: CGFloat.random(in: 0...400), y: animate ? 1000 : -100).animation(.linear(duration: Double.random(in: 2.0...5.0)).repeatForever(autoreverses: false).delay(Double.random(in: 0...4)), value: animate)
            }
        }.drawingGroup().onAppear { animate = true }.allowsHitTesting(false)
    }
}

struct StatBox: View {
    let title: String; let value: String; let color: Color
    var body: some View { VStack(spacing: 8) { Text(value).font(.headline.bold()).foregroundColor(color); Text(title).font(.caption2).foregroundColor(.gray) }.frame(maxWidth: .infinity).padding().background(.ultraThinMaterial).cornerRadius(20).overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.3), lineWidth: 1)) }
}

struct HubStatCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon).foregroundColor(color).font(.title3); Text(value).font(.headline.bold()).foregroundColor(.white); Text(title).font(.caption2).foregroundColor(.gray)
        }.frame(maxWidth: .infinity).padding(.vertical, 10).background(.ultraThinMaterial).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(AnyShapeStyle(AppTheme.glassGradient), lineWidth: 1))
    }
}
struct AnimatedBackgroundView: View {
    var isActive: Bool
    @State private var a = false
    
    var body: some View {
        ZStack {
            AppTheme.bgDark.ignoresSafeArea()
            Color.white.opacity(0.01).blendMode(.overlay).ignoresSafeArea()
            Circle().fill(AppTheme.accentRed.opacity(0.15)).blur(radius: 60).frame(width: 300).offset(x: a ? 100 : -100, y: a ? -150 : 100)
            Circle().fill(AppTheme.accentBlue.opacity(0.2)).blur(radius: 80).frame(width: 400).offset(x: a ? -100 : 150, y: a ? 200 : -50)
            Circle().fill(AppTheme.accentPurple.opacity(0.15)).blur(radius: 100).frame(width: 250).offset(x: a ? 50 : -50, y: a ? 50 : -200)
        }
        .drawingGroup()
        .onAppear {
            if isActive {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { a.toggle() }
            }
        }
        .onChange(of: isActive) { old, newActive in
            if newActive {
                withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) { a.toggle() }
            }
        }
    }
}
