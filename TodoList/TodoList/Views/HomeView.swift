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

// MARK: - 动画工具
struct AnimationUtils {
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - 动画视图修饰符
struct FadeInViewModifier: ViewModifier {
    var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
    }
}

struct PopInViewModifier: ViewModifier {
    var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .scaleEffect(isPresented ? 1 : 0.8)
    }
}

extension View {
    func fadeIn(isPresented: Bool) -> some View {
        self.modifier(FadeInViewModifier(isPresented: isPresented))
    }
    
    func popIn(isPresented: Bool) -> some View {
        self.modifier(PopInViewModifier(isPresented: isPresented))
    }
}

// MARK: - 进度条组件
struct AnimatedProgressBar: View {
    var value: Double // 0-1
    @State private var animatedValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: max(geometry.size.width * animatedValue, 0), height: geometry.size.height)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { oldValue, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedValue = newValue
            }
        }
    }
}

// MARK: - 分类选择芯片组件
struct AnimatedCategoryChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(Animation.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - 任务行组件
struct AnimatedTaskRow: View {
    var task: Task
    var toggleAction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: toggleAction) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                    .strikethrough(task.isCompleted)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let dueDate = task.dueDate {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        
                        Text(formatTime(dueDate))
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let category = task.category {
                Text(category.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
} 