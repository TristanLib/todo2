import SwiftUI

/// 用户等级进度显示组件
struct LevelProgressView: View {
    @ObservedObject private var levelManager = UserLevelManager.shared
    @State private var animateProgress = false
    @State private var showLevelUpAnimation = false
    @State private var showPointsAnimation = false
    @State private var recentPoints = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // 等级信息头部
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("等级 \(levelManager.levelData.currentLevel)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(levelManager.levelData.levelColor))
                    
                    Text(levelManager.levelData.levelTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(levelManager.levelData.totalPoints)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("总积分")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 经验值进度条
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("经验值")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(levelManager.levelData.totalExperience) / \(levelManager.levelData.experienceForNextLevel)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                // 进度条
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // 背景条
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        // 进度条
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(levelManager.levelData.levelColor).opacity(0.8),
                                        Color(levelManager.levelData.levelColor)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * (animateProgress ? levelManager.levelData.levelProgress : 0),
                                height: 12
                            )
                            .animation(.easeInOut(duration: 1.0), value: animateProgress)
                        
                        // 闪光效果
                        if animateProgress {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.0),
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(
                                    width: geometry.size.width * levelManager.levelData.levelProgress,
                                    height: 12
                                )
                                .opacity(showPointsAnimation ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5), value: showPointsAnimation)
                        }
                    }
                }
                .frame(height: 12)
                
                // 到下一级的经验值
                HStack {
                    Spacer()
                    Text("还需 \(levelManager.levelData.experienceToNextLevel) 经验值升级")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 今日统计
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("\(levelManager.getTodayPoints())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text("今日积分")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("\(levelManager.getTodayExperience())")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    Text("今日经验")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                animateProgress = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserLevelManager.levelUpNotification)) { notification in
            if let userInfo = notification.userInfo,
               let _ = userInfo["newLevel"] as? Int {
                showLevelUpAnimation = true
                
                // 播放升级动画
                withAnimation(.spring(duration: 0.8)) {
                    showLevelUpAnimation = true
                }
                
                // 2秒后隐藏动画
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLevelUpAnimation = false
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserLevelManager.pointsEarnedNotification)) { notification in
            if let pointRecord = notification.object as? PointRecord {
                recentPoints = pointRecord.points
                
                // 播放积分获得动画
                withAnimation(.easeInOut(duration: 0.3)) {
                    showPointsAnimation = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showPointsAnimation = false
                    }
                }
                
                // 更新进度条动画
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateProgress = true
                }
            }
        }
        .overlay(
            // 升级庆祝动画
            Group {
                if showLevelUpAnimation {
                    LevelUpAnimationView(level: levelManager.levelData.currentLevel)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        )
        .overlay(
            // 积分获得动画
            Group {
                if showPointsAnimation && recentPoints > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("+\(recentPoints)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .scaleEffect(showPointsAnimation ? 1.2 : 0.8)
                                .opacity(showPointsAnimation ? 1 : 0)
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
                }
            }
        )
    }
}

/// 升级动画组件
struct LevelUpAnimationView: View {
    let level: Int
    @State private var sparkleScale: CGFloat = 0.5
    @State private var sparkleRotation: Double = 0
    @State private var textScale: CGFloat = 0.5
    @State private var showText = false
    
    var body: some View {
        ZStack {
            // 闪光效果
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.title)
                    .foregroundColor(.yellow)
                    .scaleEffect(sparkleScale)
                    .rotationEffect(.degrees(sparkleRotation + Double(index * 45)))
                    .offset(
                        x: cos(Double(index * 45) * .pi / 180) * 40,
                        y: sin(Double(index * 45) * .pi / 180) * 40
                    )
            }
            
            // 升级文本
            VStack(spacing: 8) {
                Text("🎉")
                    .font(.system(size: 40))
                    .scaleEffect(textScale)
                
                if showText {
                    VStack(spacing: 4) {
                        Text("升级了!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("等级 \(level)")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundColor(.orange)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(textScale)
        }
        .onAppear {
            // 闪光动画
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                sparkleScale = 1.2
            }
            
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
            
            // 文本动画
            withAnimation(.spring(duration: 0.6)) {
                textScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showText = true
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        LevelProgressView()
        
        // 调试按钮
        HStack {
            Button("添加积分") {
                UserLevelManager.shared.addTestPoints(50)
            }
            .buttonStyle(.bordered)
            
            Button("重置") {
                UserLevelManager.shared.resetAllData()
            }
            .buttonStyle(.bordered)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}