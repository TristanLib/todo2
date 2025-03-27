import SwiftUI

// MARK: - Animation Presets

struct AnimationUtils {
    // 标准动画效果
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)
    static let easeIn = Animation.easeIn(duration: 0.3)
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.4)
    
    // 自定义动画效果
    static let quickBounce = Animation.interpolatingSpring(mass: 0.8, stiffness: 100, damping: 10, initialVelocity: 0)
    static let gentlePop = Animation.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.1)
    static let snappy = Animation.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0)
    
    // 时间
    struct Duration {
        static let short: Double = 0.2
        static let medium: Double = 0.4
        static let long: Double = 0.6
    }
}

// MARK: - View Modifiers

struct FadeInModifier: ViewModifier {
    var isPresented: Bool
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .animation(
                Animation.easeInOut(duration: AnimationUtils.Duration.medium)
                    .delay(delay),
                value: isPresented
            )
    }
}

struct SlideInModifier: ViewModifier {
    var isPresented: Bool
    var edge: Edge
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: edge == .leading ? (isPresented ? 0 : -50) :
                   edge == .trailing ? (isPresented ? 0 : 50) : 0,
                y: edge == .top ? (isPresented ? 0 : -50) :
                   edge == .bottom ? (isPresented ? 0 : 50) : 0
            )
            .opacity(isPresented ? 1 : 0)
            .animation(
                Animation.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)
                    .delay(delay),
                value: isPresented
            )
    }
}

struct ScaleEffectModifier: ViewModifier {
    var isPresented: Bool
    var delay: Double = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
            .animation(
                Animation.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0)
                    .delay(delay),
                value: isPresented
            )
    }
}

// MARK: - View Extensions

extension View {
    func fadeIn(isPresented: Bool, delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(isPresented: isPresented, delay: delay))
    }
    
    func slideIn(isPresented: Bool, from edge: Edge, delay: Double = 0) -> some View {
        self.modifier(SlideInModifier(isPresented: isPresented, edge: edge, delay: delay))
    }
    
    func popIn(isPresented: Bool, delay: Double = 0) -> some View {
        self.modifier(ScaleEffectModifier(isPresented: isPresented, delay: delay))
    }
    
    func smoothTransition() -> some View {
        self.transition(
            AnyTransition.opacity
                .combined(with: .scale(scale: 0.9))
                .animation(.easeInOut(duration: AnimationUtils.Duration.medium))
        )
    }
}

// MARK: - 自定义转场动画

extension AnyTransition {
    static var slideUp: AnyTransition {
        AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
    }
    
    static var slideDown: AnyTransition {
        AnyTransition.move(edge: .top)
            .combined(with: .opacity)
    }
    
    static var slideIn: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var popIn: AnyTransition {
        AnyTransition.scale(scale: 0.8)
            .combined(with: .opacity)
    }
} 