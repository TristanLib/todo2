import SwiftUI

/// 等级晋升庆祝动画组件
struct LevelUpCelebrationView: View {
    let oldLevel: Int
    let newLevel: Int
    let levelData: UserLevelData
    @Binding var isPresented: Bool
    let onContinue: (() -> Void)?
    
    @State private var showBackground = false
    @State private var showStars = false
    @State private var showContent = false
    @State private var showButtons = false
    @State private var starScale: CGFloat = 0.5
    @State private var starRotation: Double = 0
    @State private var confettiOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black
                .opacity(showBackground ? 0.85 : 0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: showBackground)
            
            // 粒子效果背景
            ConfettiView()
                .opacity(confettiOpacity)
                .animation(.easeInOut(duration: 1.0), value: confettiOpacity)
            
            // 闪光星星效果
            ForEach(0..<12, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                    .scaleEffect(starScale)
                    .rotationEffect(.degrees(starRotation + Double(index * 30)))
                    .offset(
                        x: cos(Double(index * 30) * .pi / 180) * 120,
                        y: sin(Double(index * 30) * .pi / 180) * 120
                    )
                    .opacity(showStars ? 1 : 0)
            }
            .animation(.spring(duration: 1.0), value: starScale)
            .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: starRotation)
            .animation(.easeInOut(duration: 0.8).delay(0.3), value: showStars)
            
            // 主要内容
            VStack(spacing: 24) {
                if showContent {
                    // 庆祝标题
                    VStack(spacing: 8) {
                        Text("🎉")
                            .font(.system(size: 60))
                            .scaleEffect(showContent ? 1.0 : 0.5)
                            .animation(.spring(duration: 0.8), value: showContent)
                        
                        Text("恭喜升级!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("你的努力得到了回报")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    // 等级变化展示
                    HStack(spacing: 20) {
                        // 旧等级
                        VStack(spacing: 8) {
                            Text("等级 \(oldLevel)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("\(oldLevel)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // 箭头
                        Image(systemName: "arrow.right")
                            .font(.title)
                            .foregroundColor(.white)
                            .scaleEffect(showContent ? 1.2 : 0.8)
                            .animation(.spring(duration: 0.6).delay(0.3), value: showContent)
                        
                        // 新等级
                        VStack(spacing: 8) {
                            Text("等级 \(newLevel)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(levelData.levelColor).opacity(0.8),
                                            Color(levelData.levelColor)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text("\(newLevel)")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color(levelData.levelColor).opacity(0.5), radius: 10)
                                .scaleEffect(showContent ? 1.0 : 0.5)
                                .animation(.spring(duration: 0.8).delay(0.2), value: showContent)
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // 等级标题展示
                    VStack(spacing: 8) {
                        Text("新头衔")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(levelData.levelTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(levelData.levelColor))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.regularMaterial)
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    // 奖励信息
                    VStack(spacing: 12) {
                        Text("升级奖励")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                Text("经验值容量提升")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                                Text("新成就解锁")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                Text("专属头衔")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(.top, 20)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // 按钮
                if showButtons {
                    HStack(spacing: 16) {
                        Button {
                            dismissCelebration()
                        } label: {
                            Text("太棒了!")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(levelData.levelColor).opacity(0.8),
                                            Color(levelData.levelColor)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                                .shadow(color: Color(levelData.levelColor).opacity(0.3), radius: 10)
                        }
                        .scaleEffect(showButtons ? 1.0 : 0.8)
                        .animation(.spring(duration: 0.6), value: showButtons)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(40)
        }
        .onAppear {
            startCelebrationSequence()
        }
    }
    
    private func startCelebrationSequence() {
        // 第一阶段：显示背景
        withAnimation(.easeInOut(duration: 0.5)) {
            showBackground = true
        }
        
        // 第二阶段：显示星星效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showStars = true
                starScale = 1.2
                starRotation = 360
                confettiOpacity = 1.0
            }
        }
        
        // 第三阶段：显示内容
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(duration: 0.8)) {
                showContent = true
            }
        }
        
        // 第四阶段：显示按钮
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(duration: 0.6)) {
                showButtons = true
            }
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showBackground = false
            showStars = false
            showContent = false
            showButtons = false
            confettiOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
            onContinue?()
        }
    }
}

/// 粒子特效组件
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        
        for _ in 0..<30 {
            let particle = ConfettiParticle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: CGFloat.random(in: -50...0)
                ),
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 4...12),
                opacity: Double.random(in: 0.5...1.0)
            )
            particles.append(particle)
        }
        
        // 让粒子下落
        withAnimation(.linear(duration: 3.0)) {
            for i in 0..<particles.count {
                particles[i].position.y += UIScreen.main.bounds.height + 100
                particles[i].opacity = 0
            }
        }
    }
}

/// 粒子数据模型
struct ConfettiParticle: Identifiable {
    let id: UUID
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    LevelUpCelebrationView(
        oldLevel: 1,
        newLevel: 2,
        levelData: UserLevelData(),
        isPresented: .constant(true),
        onContinue: nil
    )
}