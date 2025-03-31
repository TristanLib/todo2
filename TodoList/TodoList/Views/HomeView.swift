import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedCategory: TaskCategory? = nil
    @State private var isLoadingComplete = false
    @State private var showCategorySection = false
    @State private var showTasksSection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 欢迎卡片
                    welcomeCard
                        .fadeIn(isPresented: isLoadingComplete)
                    
                    // 今日概览
                    progressSection
                        .fadeIn(isPresented: isLoadingComplete)
                    
                    // 分类过滤
                    categorySection
                        .fadeIn(isPresented: showCategorySection)
                    
                    // 今日任务
                    todayTasksSection
                        .fadeIn(isPresented: showTasksSection)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("主页")
            .navigationBarItems(trailing: 
                Menu {
                    Button(action: {}) {
                        Label("搜索", systemImage: "magnifyingglass")
                    }
                    Button(action: {}) {
                        Label("排序", systemImage: "arrow.up.arrow.down")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(appSettings.accentColor.color)
                }
            )
            .onAppear {
                animateContentOnAppear()
            }
        }
    }
    
    private var welcomeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(timeDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: currentTimeIcon)
                .font(.system(size: 38))
                .foregroundColor(appSettings.accentColor.color)
                .frame(width: 70, height: 70)
                .background(appSettings.accentColor.color.opacity(0.1))
                .clipShape(Circle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日概览")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(completedTodayTasks.count)/\(todayTasks.count) 任务")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                progressCard(
                    title: "进行中",
                    count: todayTasks.filter { !$0.isCompleted }.count,
                    icon: "hourglass",
                    color: .blue
                )
                
                progressCard(
                    title: "已完成",
                    count: completedTodayTasks.count,
                    icon: "checkmark.circle",
                    color: .green
                )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("总体进度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(progressValue * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(appSettings.accentColor.color)
                }
                
                AnimatedProgressBar(value: progressValue)
                    .frame(height: 10)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            )
        }
    }
    
    private func progressCard(title: String, count: Int, icon: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    categoryChip(
                        title: "全部",
                        isSelected: selectedCategory == nil,
                        color: appSettings.accentColor.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = nil
                        }
                    }
                    
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        categoryChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category,
                            color: categoryColor(for: category)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    private func categoryChip(title: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(isSelected ? color : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func categoryColor(for category: TaskCategory) -> Color {
        switch category {
        case .work:
            return .blue
        case .personal:
            return .purple
        case .health:
            return .green
        case .important:
            return .red
        }
    }
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日任务")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: TaskListView()) {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(appSettings.accentColor.color)
                }
            }
            
            if filteredTasks.isEmpty {
                emptyTasksView
                    .popIn(isPresented: showTasksSection)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredTasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            EnhancedTaskRow(task: task)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.top, 20)
            
            Text("今日无任务")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("你的今日安排目前是空闲的")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        )
    }
    
    // MARK: - 任务行组件
    struct EnhancedTaskRow: View {
        var task: Task
        @EnvironmentObject var taskStore: TaskStore
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Button(action: {
                    withAnimation {
                        taskStore.toggleTaskCompletion(task)
                    }
                }) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? .gray : .primary)
                        .strikethrough(task.isCompleted)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 8) {
                        if let dueDate = task.dueDate {
                            Label(
                                formatTime(dueDate),
                                systemImage: "clock"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        
                        if let category = task.category {
                            Text(category.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(categoryColor(for: category).opacity(0.15))
                                )
                                .foregroundColor(categoryColor(for: category))
                        }
                    }
                }
                
                Spacer()
                
                if task.priority == .high {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            )
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        private func categoryColor(for category: TaskCategory) -> Color {
            switch category {
            case .work:
                return .blue
            case .personal:
                return .purple
            case .health:
                return .green
            case .important:
                return .red
            }
        }
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
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour < 12 {
            return "早上好"
        } else if hour < 18 {
            return "下午好"
        } else {
            return "晚上好"
        }
    }
    
    private var timeDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 EEEE"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        return dateFormatter.string(from: Date())
    }
    
    private var currentTimeIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour < 6 {
            return "moon.stars.fill"
        } else if hour < 12 {
            return "sun.max.fill"
        } else if hour < 18 {
            return "sun.min.fill"
        } else {
            return "moon.fill"
        }
    }
    
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
            .environmentObject(AppSettings())
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