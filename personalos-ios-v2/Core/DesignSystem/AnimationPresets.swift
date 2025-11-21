import SwiftUI

struct AnimationPresets {
    // MARK: - Spring Animations
    
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let springSmooth = Animation.spring(response: 0.35, dampingFraction: 0.8)
    static let springSnappy = Animation.spring(response: 0.25, dampingFraction: 0.75)
    
    // MARK: - Easing Animations
    
    static let easeIn = Animation.easeIn(duration: 0.3)
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    
    // MARK: - Custom Curves
    
    static let smooth = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.3)
    static let snappy = Animation.timingCurve(0.2, 0.8, 0.2, 1.0, duration: 0.25)
    static let gentle = Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.4)
    
    // MARK: - Contextual Animations
    
    static let cardAppear = spring
    static let cardDismiss = easeOut
    static let modalPresent = springSmooth
    static let modalDismiss = easeOut
    static let buttonTap = springSnappy
    static let toggle = springBouncy
    static let listItemAppear = smooth
    static let pullToRefresh = springBouncy
    
    // MARK: - Transition Animations
    
    static func slideIn(edge: Edge = .trailing) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge).combined(with: .opacity)
        )
    }
    
    static let scaleAndFade: AnyTransition = .scale(scale: 0.9).combined(with: .opacity)
    
    static let slideUp: AnyTransition = .move(edge: .bottom).combined(with: .opacity)
    
    static let slideDown: AnyTransition = .move(edge: .top).combined(with: .opacity)
}

// MARK: - View Extensions

extension View {
    func animateOnAppear(delay: Double = 0) -> some View {
        modifier(AppearAnimationModifier(delay: delay))
    }
    
    func shimmer(isActive: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: isActive))
    }
    
    func bounceOnTap() -> some View {
        modifier(BounceModifier())
    }
    
    func pulseEffect(isActive: Bool = true) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }
}

// MARK: - Animation Modifiers

struct AppearAnimationModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(AnimationPresets.smooth.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    if isActive {
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                    }
                }
            )
            .onAppear {
                if isActive {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

struct BounceModifier: ViewModifier {
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onTapGesture {
                withAnimation(AnimationPresets.springBouncy) {
                    scale = 0.95
                }
                withAnimation(AnimationPresets.springBouncy.delay(0.1)) {
                    scale = 1.0
                }
                HapticsManager.shared.buttonTap()
            }
    }
}

struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        scale = 1.05
                    }
                }
            }
    }
}

// MARK: - Loading Animations

struct LoadingDots: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppTheme.mistBlue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear {
            animating = true
        }
    }
}

struct LoadingSpinner: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [AppTheme.mistBlue, AppTheme.mistBlue.opacity(0.1)],
                    center: .center
                ),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
