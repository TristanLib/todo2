import SwiftUI

struct AchievementBadgeView: View {
    let achievement: Achievement
    @State private var isAnimating = false
    
    private var isUnlocked: Bool {
        achievement.isUnlocked
    }
    
    private var iconColor: Color {
        isUnlocked ? .primary : .secondary
    }
    
    private var textColor: Color {
        isUnlocked ? .primary : .secondary
    }
    
    private var cardBackground: Color {
        isUnlocked ? Color(.systemBackground) : Color(.systemGray6)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 图标
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isAnimating)
            
            // 标题
            Text(achievement.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // 描述
            Text(achievement.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // 解锁日期 (仅已解锁)
            if isUnlocked, let unlockedDate = achievement.unlockedDate {
                Label {
                    Text(formatDate(unlockedDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isUnlocked ? 1.0 : 0.95)
        .opacity(isUnlocked ? 1.0 : 0.7)
        .onAppear {
            if isUnlocked {
                isAnimating = true
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct AchievementBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    AchievementBadgeView(achievement: unlockedAchievement)
                    AchievementBadgeView(achievement: lockedAchievement)
                }
                .padding()
            }
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.light)
            
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    AchievementBadgeView(achievement: unlockedAchievement)
                    AchievementBadgeView(achievement: lockedAchievement)
                }
                .padding()
            }
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
        }
    }
    
    static var unlockedAchievement: Achievement {
        var achievement = Achievement(
            id: "test_unlocked",
            title: "测试成就",
            description: "这是一个已解锁的测试成就",
            icon: "star.fill",
            category: .special,
            rewardPoints: 100
        )
        achievement.isUnlocked = true
        achievement.unlockedDate = Date()
        return achievement
    }
    
    static var lockedAchievement: Achievement {
        return Achievement(
            id: "test_locked",
            title: "锁定成就",
            description: "这是一个未解锁的测试成就",
            icon: "lock.fill",
            category: .special,
            rewardPoints: 100
        )
    }
}