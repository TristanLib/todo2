import SwiftUI

struct AchievementGridView: View {
    @StateObject private var achievementManager = AchievementManager.shared
    @State private var selectedCategory: AchievementCategory? = nil
    @State private var showUnlockedOnly = false
    
    // 3列网格布局
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    private var filteredAchievements: [Achievement] {
        var achievements = achievementManager.getAllAchievements()
        
        // 分类筛选
        if let category = selectedCategory {
            achievements = achievements.filter { $0.category == category }
        }
        
        // 解锁状态筛选
        if showUnlockedOnly {
            achievements = achievements.filter { $0.isUnlocked }
        }
        
        return achievements
    }
    
    private var progressInfo: (unlocked: Int, total: Int, percentage: Double) {
        let all = achievementManager.getAllAchievements()
        let unlocked = all.filter { $0.isUnlocked }.count
        let total = all.count
        let percentage = total > 0 ? Double(unlocked) / Double(total) : 0.0
        return (unlocked, total, percentage)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 进度概览
                    progressOverviewSection
                    
                    // 筛选栏
                    filterSection
                    
                    // 成就网格
                    achievementGridSection
                }
                .padding()
            }
            .navigationTitle("我的成就")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showUnlockedOnly.toggle()
                    }) {
                        Image(systemName: showUnlockedOnly ? "eye.fill" : "eye")
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Overview Section
    
    private var progressOverviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("总体进度")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(progressInfo.unlocked)/\(progressInfo.total) 已解锁")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 圆形进度指示器
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: progressInfo.percentage)
                        .stroke(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: progressInfo.percentage)
                    
                    Text("\(Int(progressInfo.percentage * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            
            // 进度条
            ProgressView(value: progressInfo.percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类筛选")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // 全部
                    FilterChip(
                        title: "全部",
                        icon: "circle.grid.3x3",
                        isSelected: selectedCategory == nil,
                        action: { selectedCategory = nil }
                    )
                    
                    // 各分类
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        FilterChip(
                            title: category.localizedName,
                            icon: category.icon,
                            isSelected: selectedCategory == category,
                            action: { 
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Achievement Grid Section
    
    private var achievementGridSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(selectedCategory?.localizedName ?? "所有成就")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(filteredAchievements.count) 项")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if filteredAchievements.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text(showUnlockedOnly ? "还没有解锁的成就" : "暂无成就")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(showUnlockedOnly ? "完成任务和专注时间来解锁成就吧！" : "成就系统加载中...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredAchievements) { achievement in
                        AchievementBadgeView(achievement: achievement)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut, value: filteredAchievements.count)
            }
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.orange : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct AchievementGridView_Previews: PreviewProvider {
    static var previews: some View {
        AchievementGridView()
            .preferredColorScheme(.light)
        
        AchievementGridView()
            .preferredColorScheme(.dark)
    }
}