import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var selectedCategory: TaskCategory? = nil
    @State private var selectedCustomCategory: CustomCategory? = nil
    @State private var isLoadingComplete = false
    @State private var showCategorySection = false
    @State private var showTasksSection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // 欢迎卡片
                    welcomeCard
                        .fadeIn(isPresented: isLoadingComplete)
                    
                    // 今日概览
                    progressSection
                        .fadeIn(isPresented: isLoadingComplete)
                    
                    // 待处理任务
                    if !overdueIncompleteTasks.isEmpty {
                        pendingTasksSection
                            .fadeIn(isPresented: isLoadingComplete)
                    }
                    
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
                DispatchQueue.main.async {
                    animateContentOnAppear()
                }
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
                .font(.system(size: 44))
                .foregroundColor(appSettings.accentColor.color)
                .frame(width: 75, height: 75)
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
            HStack(spacing: 8) {
                Text("任务概览")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("(\(completedTodayTasks.count)/\(todayTasks.count))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                progressCard(
                    title: "今日进行中",
                    count: todayTasks.filter { !$0.isCompleted }.count,
                    icon: "hourglass.circle.fill",
                    color: .blue
                )
                
                progressCard(
                    title: "全部未完成",
                    count: allIncompleteTasks.count,
                    icon: "exclamationmark.circle.fill",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                progressCard(
                    title: "已逾期",
                    count: overdueIncompleteTasks.count,
                    icon: "calendar.badge.exclamationmark",
                    color: .red
                )
                
                progressCard(
                    title: "已完成",
                    count: completedTodayTasks.count,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("今日进度")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(progressValue * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(appSettings.accentColor.color)
                }
                
                AnimatedProgressBar(value: progressValue)
                    .frame(height: 12)
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
        HStack(alignment: .center) {
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
                .font(.system(size: 28))
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
                HStack(spacing: 14) {
                    // 全部分类选项
                    categoryChip(
                        iconName: "list.bullet",
                        title: "全部",
                        isSelected: selectedCategory == nil && selectedCustomCategory == nil,
                        color: appSettings.accentColor.color
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = nil
                            selectedCustomCategory = nil
                        }
                    }
                    
                    // 预设分类
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        categoryChip(
                            iconName: categoryIcon(for: category),
                            title: category.localizedName,
                            isSelected: selectedCategory == category && selectedCustomCategory == nil,
                            color: categoryColor(for: category)
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                                selectedCustomCategory = nil
                            }
                        }
                    }
                    
                    // 自定义分类
                    ForEach(categoryManager.categories) { customCategory in
                        // 排除与预设分类名称重复的自定义分类（避免重复显示）
                        if !isDefaultCategory(customCategory) {
                            categoryChip(
                                iconName: "tag.fill",
                                title: customCategory.name,
                                isSelected: selectedCustomCategory?.id == customCategory.id && selectedCategory == nil,
                                color: CategoryManager.color(for: customCategory.colorName)
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCustomCategory = customCategory
                                    selectedCategory = nil
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
    
    private func categoryChip(iconName: String?, title: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 13, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
            }
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
    
    // Helper function to get icon name for category
    private func categoryIcon(for category: TaskCategory) -> String {
        switch category {
        case .work:
            return "briefcase.fill"
        case .personal:
            return "person.fill"
        case .health:
            return "heart.fill"
        case .important:
            return "exclamationmark.triangle.fill"
        }
    }
    
    // 检查自定义分类是否与预设分类重复
    private func isDefaultCategory(_ customCategory: CustomCategory) -> Bool {
        return customCategory.name == "工作" || 
               customCategory.name == "个人" || 
               customCategory.name == "健康" || 
               customCategory.name == "重要"
    }
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日待办")
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
                List {
                    ForEach(filteredTasks) { task in
                        NavigationLink(destination: TaskDetailView(task: task)) {
                            EnhancedTaskRow(task: task)
                                .padding(.vertical, 4)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteTask)
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
                .frame(minHeight: 300)
            }
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            let task = filteredTasks[index]
            taskStore.deleteTask(task)
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
            .contentShape(Rectangle())
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
        DispatchQueue.main.async {
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
    
    private var allIncompleteTasks: [Task] {
        taskStore.getIncompleteTasks()
    }
    
    private var overdueIncompleteTasks: [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return taskStore.getIncompleteTasks().filter { task in
            if let dueDate = task.dueDate {
                let dueDay = calendar.startOfDay(for: dueDate)
                return dueDay < today
            }
            return false
        }
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
        } else if let customCategory = selectedCustomCategory {
            return todayTasks.filter { task in
                if let taskCustomCategory = task.customCategory {
                    return taskCustomCategory.id == customCategory.id
                }
                return false
            }
        } else {
            return todayTasks
        }
    }
    
    // 添加待处理任务部分
    private var pendingTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("已逾期任务")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !overdueIncompleteTasks.isEmpty {
                    Text("\(overdueIncompleteTasks.count)个未完成")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if overdueIncompleteTasks.isEmpty {
                Text("没有逾期未完成的任务")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    )
            } else {
                ForEach(overdueIncompleteTasks.prefix(3)) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(task.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if task.priority == .high {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            HStack {
                                if let dueDate = task.dueDate {
                                    HStack {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .foregroundColor(.red)
                                        
                                        Text(formatDate(dueDate))
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                Spacer()
                                
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
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if overdueIncompleteTasks.count > 3 {
                    NavigationLink(destination: TaskListView(initialFilter: .active)) {
                        Text("查看全部\(overdueIncompleteTasks.count)个逾期任务")
                            .font(.subheadline)
                            .foregroundColor(appSettings.accentColor.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
            .environmentObject(CategoryManager())
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
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    animatedValue = value
                }
            }
        }
        .onChange(of: value) { oldValue, newValue in
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animatedValue = newValue
                }
            }
        }
    }
}

// 添加日期格式化辅助函数
private func formatDate(_ date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM月dd日"
    return dateFormatter.string(from: date)
} 