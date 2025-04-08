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
    
    // Helper for localized date formatting
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none // Don't show time for the main date string
        formatter.doesRelativeDateFormatting = true // Use relative terms like "Today", "Yesterday"
        return formatter
    }
    
    // Helper for localized weekday formatting
    private var weekdayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // Full weekday name
        return formatter
    }
    
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
            .navigationTitle(NSLocalizedString("主页", comment: "Home navigation title"))
            .navigationBarItems(trailing: 
                Menu {
                    Button(action: {}) {
                        Label(NSLocalizedString("搜索", comment: "Search menu item"), systemImage: "magnifyingglass")
                    }
                    Button(action: {}) {
                        Label(NSLocalizedString("排序", comment: "Sort menu item"), systemImage: "arrow.up.arrow.down")
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
                
                Text("\(dateFormatter.string(from: Date())), \(weekdayFormatter.string(from: Date()))")
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
                Text(NSLocalizedString("任务概览", comment: "Task overview title"))
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
                    title: NSLocalizedString("今日进行中", comment: "Today in progress card"),
                    count: todayTasks.filter { !$0.isCompleted }.count,
                    icon: "hourglass.circle.fill",
                    color: .blue
                )
                
                progressCard(
                    title: NSLocalizedString("全部未完成", comment: "All incomplete card"),
                    count: allIncompleteTasks.count,
                    icon: "exclamationmark.circle.fill",
                    color: .orange
                )
            }
            
            HStack(spacing: 12) {
                progressCard(
                    title: NSLocalizedString("已逾期", comment: "Overdue card"),
                    count: overdueIncompleteTasks.count,
                    icon: "calendar.badge.exclamationmark",
                    color: .red
                )
                
                progressCard(
                    title: NSLocalizedString("已完成", comment: "Completed card"),
                    count: completedTodayTasks.count,
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(NSLocalizedString("今日进度", comment: "Today's progress"))
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
    
    @State private var showEmptyTaskAlert = false
    @State private var emptyAlertTitle = ""
    @State private var emptyAlertMessage = ""
    
    private func progressCard(title: String, count: Int, icon: String, color: Color) -> some View {
        let cardContent = HStack(alignment: .center) {
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
        
        return Group {
            if count == 0 {
                cardContent
                    .onTapGesture {
                        if title == NSLocalizedString("今日进行中", comment: "Today in progress card") {
                            emptyAlertTitle = NSLocalizedString("今日无进行中任务", comment: "No in-progress tasks today")
                            emptyAlertMessage = NSLocalizedString("今天没有需要处理的任务", comment: "No tasks to handle today")
                        } else if title == NSLocalizedString("全部未完成", comment: "All incomplete card") {
                            emptyAlertTitle = NSLocalizedString("没有未完成任务", comment: "No incomplete tasks")
                            emptyAlertMessage = NSLocalizedString("你已完成所有任务", comment: "You have completed all tasks")
                        } else if title == NSLocalizedString("已逾期", comment: "Overdue card") {
                            emptyAlertTitle = NSLocalizedString("没有逾期任务", comment: "No overdue tasks")
                            emptyAlertMessage = NSLocalizedString("你没有逾期的任务", comment: "You don't have any overdue tasks")
                        } else if title == NSLocalizedString("已完成", comment: "Completed card") {
                            emptyAlertTitle = NSLocalizedString("没有已完成任务", comment: "No completed tasks")
                            emptyAlertMessage = NSLocalizedString("你还没有完成任何任务", comment: "You haven't completed any tasks yet")
                        }
                        showEmptyTaskAlert = true
                    }
                    .alert(isPresented: $showEmptyTaskAlert) {
                        Alert(
                            title: Text(emptyAlertTitle),
                            message: Text(emptyAlertMessage),
                            dismissButton: .default(Text(NSLocalizedString("确定", comment: "OK")))
                        )
                    }
            } else if title == NSLocalizedString("今日进行中", comment: "Today in progress card") {
                NavigationLink(destination: TaskListView(showTodayOnly: true)) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else if title == NSLocalizedString("全部未完成", comment: "All incomplete card") {
                NavigationLink(destination: TaskListView(showAllIncomplete: true)) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else if title == NSLocalizedString("已逾期", comment: "Overdue card") {
                NavigationLink(destination: TaskListView(showOverdueOnly: true)) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else if title == NSLocalizedString("已完成", comment: "Completed card") {
                NavigationLink(destination: TaskListView(showCompletedOnly: true)) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("分类", comment: "Categories title"))
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    // 全部分类选项 - Use NSLocalizedString
                    categoryChip(
                        iconName: "list.bullet",
                        title: NSLocalizedString("全部", comment: "All categories filter chip"), // Localized
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
                            title: category.localizedString,
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
    
    // 检查自定义分类是否与预设分类重复 - Use localizedString comparison
    private func isDefaultCategory(_ customCategory: CustomCategory) -> Bool {
        // Compare custom category name against the localized names of presets
        return TaskCategory.allCases.contains { $0.localizedString == customCategory.name }
    }
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("今日待办", comment: "Today's Todos section title"))
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                NavigationLink(destination: TaskListView()) {
                    Text(NSLocalizedString("查看全部", comment: "View All button"))
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
            
            Text(NSLocalizedString("今日无任务", comment: "No tasks today title"))
                .font(.headline)
                .foregroundColor(.gray)
            
            Text(NSLocalizedString("你的今日安排目前是空闲的", comment: "Empty schedule message"))
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
                            Text(category.localizedString)
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
            return NSLocalizedString("早上好", comment: "Good morning greeting")
        } else if hour < 18 {
            return NSLocalizedString("下午好", comment: "Good afternoon greeting")
        } else {
            return NSLocalizedString("晚上好", comment: "Good evening greeting")
        }
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
    
    // MARK: - Helper Views for HomeView

    // Extracted View for a single overdue task row
    private struct OverdueTaskRowView: View {
        let task: Task
        @EnvironmentObject var appSettings: AppSettings // Needed for accent color possibly
        // Function to get color for preset category (copied or passed down)
        let categoryColor: (TaskCategory) -> Color
        // Function to format date (copied or passed down)
        let formatDate: (Date) -> String
        
        var body: some View {
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
                    
                    // Corrected Category Display Logic
                    if let category = task.category {
                        Text(category.localizedString)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(categoryColor(category).opacity(0.15))
                            )
                            .foregroundColor(categoryColor(category))
                    } else if let customCategory = task.customCategory {
                        Text(customCategory.localizedName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(CategoryManager.color(for: customCategory.colorName).opacity(0.15))
                            )
                            .foregroundColor(CategoryManager.color(for: customCategory.colorName))
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
    }

    // 添加待处理任务部分 (Refactored)
    private var pendingTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("已逾期任务", comment: "Overdue tasks section title"))
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !overdueIncompleteTasks.isEmpty {
                    Text(String.localizedStringWithFormat(
                        NSLocalizedString("%d个未完成", comment: "Number of incomplete tasks badge"),
                        overdueIncompleteTasks.count
                    ))
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if overdueIncompleteTasks.isEmpty {
                Text(NSLocalizedString("没有逾期未完成的任务", comment: "No overdue tasks message"))
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
                // Use the extracted view within ForEach
                ForEach(overdueIncompleteTasks.prefix(3)) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        // Pass helper functions needed by the subview
                        OverdueTaskRowView(task: task, categoryColor: self.categoryColor, formatDate: self.formatDate)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if overdueIncompleteTasks.count > 3 {
                    NavigationLink(destination: TaskListView(initialFilter: .active)) {
                        Text(String.localizedStringWithFormat(
                            NSLocalizedString("查看全部%d个逾期任务", comment: "View all overdue tasks button"), 
                            overdueIncompleteTasks.count
                        ))
                            .font(.subheadline)
                            .foregroundColor(appSettings.accentColor.color)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // Helper to format date for overdue tasks (kept for passing to subview)
    private func formatDate(_ date: Date) -> String {
         let formatter = DateFormatter()
         formatter.dateStyle = .short
         formatter.timeStyle = .none
         return formatter.string(from: date)
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