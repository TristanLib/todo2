import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var selectedCategory: TaskCategory? = nil
    @State private var isLoadingComplete = false
    @State private var showCategorySection = false
    @State private var showTasksSection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    progressSection
                        .fadeIn(isPresented: isLoadingComplete)
                    
                    categorySection
                        .fadeIn(isPresented: showCategorySection)
                    
                    todayTasksSection
                        .fadeIn(isPresented: showTasksSection)
                }
                .padding()
            }
            .navigationTitle("主页")
            .navigationBarItems(trailing: Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            })
            .onAppear {
                animateContentOnAppear()
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("今日进度")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(completedTodayTasks.count)/\(todayTasks.count) 任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            AnimatedProgressBar(value: progressValue)
                .frame(height: 8)
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("分类")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    AnimatedCategoryChip(
                        title: "全部",
                        isSelected: selectedCategory == nil
                    ) {
                        withAnimation(AnimationUtils.spring) {
                            selectedCategory = nil
                        }
                    }
                    
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        AnimatedCategoryChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(AnimationUtils.spring) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今日任务")
                .font(.title3)
                .fontWeight(.bold)
            
            if filteredTasks.isEmpty {
                emptyTasksView
                    .popIn(isPresented: showTasksSection)
            } else {
                tasksContent
            }
        }
    }
    
    private var tasksContent: some View {
        VStack(spacing: 12) {
            ForEach(Array(filteredTasks.enumerated()), id: \.element.id) { index, task in
                AnimatedTaskRow(task: task) {
                    taskStore.toggleTaskCompletion(task)
                }
                .transition(.opacity)
                .id(task.id)
            }
        }
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("今日无任务")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击 + 按钮添加新任务")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // MARK: - 动画方法
    
    private func animateContentOnAppear() {
        // 设置延迟时间来创建连续的动画效果
        withAnimation(AnimationUtils.spring.delay(0.1)) {
            isLoadingComplete = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(AnimationUtils.spring) {
                showCategorySection = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(AnimationUtils.spring) {
                showTasksSection = true
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var todayTasks: [Task] {
        taskStore.getTasksDueToday()
    }
    
    private var completedTodayTasks: [Task] {
        todayTasks.filter { $0.isCompleted }
    }
    
    private var progressValue: Double {
        guard !todayTasks.isEmpty else { return 0 }
        return Double(completedTodayTasks.count) / Double(todayTasks.count)
    }
    
    private var filteredTasks: [Task] {
        if let category = selectedCategory {
            return todayTasks.filter { $0.category == category }
        } else {
            return todayTasks
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TaskStore())
    }
} 