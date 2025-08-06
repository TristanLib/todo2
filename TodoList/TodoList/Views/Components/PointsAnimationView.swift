import SwiftUI

/// 积分获得动画组件
struct PointsAnimationView: View {
    let points: Int
    let action: PointAction
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
                
                Text("+\(points)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(action.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(y: yOffset)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                yOffset = -30
                opacity = 0.0
            }
            
            // 3秒后自动消失
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                isPresented = false
            }
        }
    }
    
    private var iconName: String {
        switch action {
        case .completeTask:
            return "checkmark.circle.fill"
        case .createTask:
            return "plus.circle.fill"
        case .completeFocusSession:
            return "timer.circle.fill"
        case .reachMilestone:
            return "star.circle.fill"
        case .unlockAchievement:
            return "trophy.circle.fill"
        case .perfectDay:
            return "crown.fill"
        case .longFocusSession:
            return "clock.circle.fill"
        case .earlyBird:
            return "sunrise.circle.fill"
        case .nightOwl:
            return "moon.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch action {
        case .completeTask:
            return .green
        case .createTask:
            return .blue
        case .completeFocusSession:
            return .orange
        case .reachMilestone:
            return .yellow
        case .unlockAchievement:
            return .purple
        case .perfectDay:
            return .pink
        case .longFocusSession:
            return .red
        case .earlyBird:
            return .yellow
        case .nightOwl:
            return .indigo
        }
    }
}

/// 全屏积分动画管理器
struct PointsAnimationManager: View {
    @State private var activeAnimations: [PointsAnimationData] = []
    
    var body: some View {
        ZStack {
            ForEach(activeAnimations) { animation in
                PointsAnimationView(
                    points: animation.points,
                    action: animation.action,
                    isPresented: .constant(true)
                )
                .position(animation.position)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
                .id(animation.id)
            }
        }
        .allowsHitTesting(false) // 不阻挡用户交互
        .onReceive(NotificationCenter.default.publisher(for: UserLevelManager.pointsEarnedNotification)) { notification in
            if let pointRecord = notification.object as? PointRecord {
                addPointsAnimation(for: pointRecord)
            }
        }
    }
    
    private func addPointsAnimation(for record: PointRecord) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // 随机位置显示动画
        let randomX = CGFloat.random(in: 100...(screenWidth - 100))
        let randomY = CGFloat.random(in: 200...(screenHeight - 200))
        
        let animationData = PointsAnimationData(
            id: UUID(),
            points: record.points,
            action: record.action,
            position: CGPoint(x: randomX, y: randomY)
        )
        
        withAnimation(.spring(duration: 0.3)) {
            activeAnimations.append(animationData)
        }
        
        // 3秒后移除动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                activeAnimations.removeAll { $0.id == animationData.id }
            }
        }
    }
}

/// 积分动画数据模型
struct PointsAnimationData: Identifiable {
    let id: UUID
    let points: Int
    let action: PointAction
    let position: CGPoint
}

/// 简化的积分提示横幅
struct PointsBannerView: View {
    let points: Int
    let action: PointAction
    @Binding var isPresented: Bool
    
    @State private var slideOffset: CGFloat = -100
    
    var body: some View {
        VStack {
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("+\(points) 积分")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(action.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .offset(y: slideOffset)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                slideOffset = 0
            }
            
            // 3秒后自动滑出
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    slideOffset = -100
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack(spacing: 20) {
            PointsAnimationView(
                points: 10,
                action: .completeTask,
                isPresented: .constant(true)
            )
            
            PointsBannerView(
                points: 50,
                action: .unlockAchievement,
                isPresented: .constant(true)
            )
        }
    }
}