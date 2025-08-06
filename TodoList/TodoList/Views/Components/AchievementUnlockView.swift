import SwiftUI

struct AchievementUnlockView: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    let onViewAllAchievements: (() -> Void)?
    
    @State private var scale: CGFloat = 0.1
    @State private var rotation: Double = 0
    @State private var sparkleScale: CGFloat = 0.5
    @State private var backgroundOpacity: Double = 0
    
    init(achievement: Achievement, isPresented: Binding<Bool>, onViewAllAchievements: (() -> Void)? = nil) {
        self.achievement = achievement
        self._isPresented = isPresented
        self.onViewAllAchievements = onViewAllAchievements
    }
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }
            
            VStack(spacing: 24) {
                // 庆祝标题
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "party.popper.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .scaleEffect(sparkleScale)
                        
                        Text("🎉 恭喜！🎉")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Image(systemName: "party.popper.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .scaleEffect(sparkleScale)
                    }
                    
                    Text("解锁新成就")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // 成就徽章展示
                VStack(spacing: 16) {
                    // 徽章图标 - 大尺寸
                    Image(systemName: achievement.icon)
                        .font(.system(size: 80))
                        .foregroundColor(.orange)
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                    
                    // 成就信息
                    VStack(spacing: 8) {
                        Text(achievement.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(achievement.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        // 奖励积分
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("+\(achievement.rewardPoints) 积分")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(24)
                .background(.regularMaterial)
                .cornerRadius(20)
                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // 操作按钮
                HStack(spacing: 16) {
                    Button(action: {
                        dismissWithAnimation()
                    }) {
                        Text("继续")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    
                    if onViewAllAchievements != nil {
                        Button(action: {
                            dismissWithAnimation()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onViewAllAchievements?()
                            }
                        }) {
                            Text("查看所有成就")
                                .font(.headline)
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
            }
            .padding(32)
            .scaleEffect(scale)
        }
        .onAppear {
            startCelebrationAnimation()
        }
    }
    
    private func startCelebrationAnimation() {
        // 背景淡入
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 0.8
        }
        
        // 主要弹窗动画
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
            scale = 1.0
        }
        
        // 图标旋转动画
        withAnimation(.spring(response: 1.0, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
            rotation = 360
        }
        
        // 闪烁动画
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4)) {
            sparkleScale = 1.2
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            backgroundOpacity = 0
            scale = 0.8
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Preview

struct AchievementUnlockView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AchievementUnlockView(
                achievement: sampleAchievement,
                isPresented: .constant(true),
                onViewAllAchievements: {}
            )
            .preferredColorScheme(.light)
            
            AchievementUnlockView(
                achievement: sampleAchievement,
                isPresented: .constant(true),
                onViewAllAchievements: {}
            )
            .preferredColorScheme(.dark)
        }
    }
    
    static var sampleAchievement: Achievement {
        var achievement = Achievement(
            id: "first_pomodoro",
            title: "初试身手",
            description: "完成第一个番茄钟",
            icon: "timer",
            category: .focus,
            rewardPoints: 50
        )
        achievement.isUnlocked = true
        achievement.unlockedDate = Date()
        return achievement
    }
}