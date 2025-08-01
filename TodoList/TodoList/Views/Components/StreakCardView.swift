import SwiftUI

struct StreakCardView: View {
    @StateObject private var streakManager = StreakManager.shared
    @State private var showCelebration = false
    @State private var animationAmount = 0.0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // 火焰图标
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .scaleEffect(1 + animationAmount * 0.1)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animationAmount)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("连续使用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(streakManager.streakData.currentStreak)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .contentTransition(.numericText())
                        
                        Text("天")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: streakManager.streakData.currentStreak)
                }
                
                Spacer()
                
                // 状态指示器
                StatusIndicatorView(status: streakManager.getCurrentStatus())
            }
            
            // 进度条和下一里程碑
            if let nextMilestone = streakManager.getNextMilestone() {
                ProgressTowardsMilestone(
                    current: streakManager.streakData.currentStreak,
                    target: nextMilestone.days,
                    title: nextMilestone.localizedTitle
                )
            } else {
                // 已达到最高级别
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("🏆 已达到最高级别！")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
            }
            
            // 最长记录显示
            if streakManager.streakData.longestStreak > streakManager.streakData.currentStreak {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Text("最长记录: \(streakManager.streakData.longestStreak)天")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // 今日状态提示
            if !streakManager.todayMarkedActive {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("完成任务或专注来保持连续记录")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: streakManager.streakData.currentStreak > 0 
                            ? [.orange.opacity(0.3), .red.opacity(0.3)]
                            : [Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            animationAmount = 1.0
        }
        .onReceive(NotificationCenter.default.publisher(for: .streakMilestoneUnlocked)) { notification in
            if let milestone = notification.object as? StreakMilestone {
                showMilestoneCelebration(milestone)
            }
        }
        .overlay(
            // 庆祝动画覆盖层
            celebrationOverlay
        )
    }
    
    @ViewBuilder
    private var celebrationOverlay: some View {
        if showCelebration {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                CelebrationAnimationView()
                    .transition(.scale.combined(with: .opacity))
            }
            .onTapGesture {
                withAnimation {
                    showCelebration = false
                }
            }
        }
    }
    
    private func showMilestoneCelebration(_ milestone: StreakMilestone) {
        withAnimation(.spring()) {
            showCelebration = true
        }
        
        // 自动隐藏庆祝动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showCelebration = false
            }
        }
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
        
        print("🎉 StreakCardView: 显示里程碑庆祝 - \(milestone.localizedTitle)")
    }
}

// MARK: - 状态指示器组件
struct StatusIndicatorView: View {
    let status: StreakStatus
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(status == .continuing ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: status == .continuing)
            
            Text(status.localizedDescription)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.1))
        )
    }
    
    private var statusColor: Color {
        switch status {
        case .continuing:
            return .green
        case .gracePeriod:
            return .orange
        case .broken:
            return .red
        case .newStart:
            return .blue
        }
    }
}

// MARK: - 里程碑进度组件
struct ProgressTowardsMilestone: View {
    let current: Int
    let target: Int
    let title: String
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
    
    private var remainingDays: Int {
        max(0, target - current)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("距离 \"\(title)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(current)/\(target)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if remainingDays > 0 {
                        Text("还需\(remainingDays)天")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    
                    // 进度
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.easeInOut(duration: 0.8), value: progress)
                    
                    // 进度点
                    if progress > 0.05 && progress < 0.95 {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .offset(x: geometry.size.width * progress - 4)
                            .animation(.easeInOut(duration: 0.8), value: progress)
                    }
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - 庆祝动画组件
struct CelebrationAnimationView: View {
    @State private var sparkleAnimation = false
    @State private var scaleAnimation = false
    @State private var rotationAnimation = 0.0
    
    var body: some View {
        VStack(spacing: 24) {
            // 主图标动画
            ZStack {
                // 背景光环
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.orange.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(scaleAnimation ? 1.2 : 0.8)
                    .opacity(scaleAnimation ? 0.7 : 0.3)
                
                // 主火焰图标
                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                    .scaleEffect(scaleAnimation ? 1.1 : 0.9)
                    .rotationEffect(.degrees(rotationAnimation))
            }
            
            // 恭喜文字
            VStack(spacing: 12) {
                Text("🎉 太棒了！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("达成新的里程碑")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .scaleEffect(scaleAnimation ? 1.0 : 0.8)
            .opacity(scaleAnimation ? 1.0 : 0.0)
            
            // 火花效果
            HStack(spacing: 20) {
                ForEach(0..<5) { index in
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                        .opacity(sparkleAnimation ? 1.0 : 0.0)
                        .scaleEffect(sparkleAnimation ? 1.0 : 0.3)
                        .offset(
                            x: sparkleAnimation ? CGFloat.random(in: -30...30) : 0,
                            y: sparkleAnimation ? CGFloat.random(in: -20...20) : 0
                        )
                        .animation(
                            .easeInOut(duration: 0.6)
                            .delay(Double(index) * 0.1)
                            .repeatCount(3, autoreverses: true),
                            value: sparkleAnimation
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
                scaleAnimation = true
            }
            
            withAnimation(.easeInOut(duration: 2.0)) {
                rotationAnimation = 360
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                sparkleAnimation = true
            }
        }
    }
}

// MARK: - 预览
struct StreakCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            StreakCardView()
            
            // 不同状态的预览
            Group {
                StreakCardView()
                StreakCardView()
                StreakCardView()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .previewLayout(.sizeThatFits)
    }
}