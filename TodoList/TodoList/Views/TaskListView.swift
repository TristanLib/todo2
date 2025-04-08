import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var selectedFilter: TaskFilter
    @State private var searchText = ""
    
    // Additional filter parameters
    var showTodayOnly: Bool = false
    var showOverdueOnly: Bool = false
    var showAllIncomplete: Bool = false
    var showCompletedOnly: Bool = false
    
    enum TaskFilter {
        case all, active, completed
    }
    
    init(initialFilter: TaskFilter = .all, showTodayOnly: Bool = false, showOverdueOnly: Bool = false, showAllIncomplete: Bool = false, showCompletedOnly: Bool = false) {
        _selectedFilter = State(initialValue: initialFilter)
        self.showTodayOnly = showTodayOnly
        self.showOverdueOnly = showOverdueOnly
        self.showAllIncomplete = showAllIncomplete
        self.showCompletedOnly = showCompletedOnly
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 过滤选项卡
                filterTabBar
                
                // 搜索栏
                searchBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                if filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("任务列表", comment: "Navigation title for task list"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            // 排序操作
                        }) {
                            Label(NSLocalizedString("按日期排序", comment: "Sort by date"), systemImage: "calendar")
                        }
                        
                        Button(action: {
                            // 排序操作
                        }) {
                            Label(NSLocalizedString("按优先级排序", comment: "Sort by priority"), systemImage: "exclamationmark.triangle")
                        }
                        
                        Divider()
                        
                        Button(action: {
                            // 显示已完成任务
                        }) {
                            Label(NSLocalizedString("显示已完成", comment: "Show completed"), systemImage: "eye")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(appSettings.accentColor.color)
                    }
                }
            }
        }
    }
    
    private var filterTabBar: some View {
        HStack(spacing: 10) {
            filterTab(title: NSLocalizedString("全部", comment: "All tasks filter"), filter: .all)
            filterTab(title: NSLocalizedString("进行中", comment: "Active tasks filter"), filter: .active)
            filterTab(title: NSLocalizedString("已完成", comment: "Completed tasks filter"), filter: .completed)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .background(Color(.systemGroupedBackground))
    }
    
    private func filterTab(title: String, filter: TaskFilter) -> some View {
        let isSelected = filter == selectedFilter
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedFilter = filter
            }
        }) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? appSettings.accentColor.color : Color(.systemGray6)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(NSLocalizedString("搜索任务...", comment: "Search tasks placeholder"), text: $searchText)
                .foregroundColor(.primary)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
                .padding(.top, 60)
            
            Text(emptyStateMessage)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateMessage: String {
        if showTodayOnly {
            return NSLocalizedString("今日没有任务", comment: "No tasks today message")
        } else if showOverdueOnly {
            return NSLocalizedString("没有逾期任务", comment: "No overdue tasks message")
        } else if showAllIncomplete {
            return NSLocalizedString("没有未完成的任务", comment: "No incomplete tasks message")
        } else if showCompletedOnly {
            return NSLocalizedString("没有已完成的任务", comment: "No completed tasks message")
        }
        
        switch selectedFilter {
        case .all:
            return searchText.isEmpty ? 
                NSLocalizedString("你的任务列表是空的", comment: "Empty task list message") : 
                NSLocalizedString("没有找到匹配的任务", comment: "No matching tasks message")
        case .active:
            return NSLocalizedString("没有进行中的任务", comment: "No active tasks message")
        case .completed:
            return NSLocalizedString("没有完成的任务", comment: "No completed tasks message")
        }
    }
    
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        EnhancedTaskRow(task: task)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var filteredTasks: [Task] {
        var tasks = taskStore.tasks
        
        // 应用特殊过滤器
        if showTodayOnly {
            tasks = taskStore.getTasksDueToday()
        } else if showOverdueOnly {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            
            tasks = tasks.filter { task in
                if let dueDate = task.dueDate {
                    let dueDay = calendar.startOfDay(for: dueDate)
                    return dueDay < today && !task.isCompleted
                }
                return false
            }
        } else if showAllIncomplete {
            tasks = tasks.filter { !$0.isCompleted }
        } else if showCompletedOnly {
            tasks = tasks.filter { $0.isCompleted }
        } else {
            // 应用标准过滤器
            switch selectedFilter {
            case .all: break
            case .active:
                tasks = tasks.filter { !$0.isCompleted }
            case .completed:
                tasks = tasks.filter { $0.isCompleted }
            }
        }
        
        // 应用搜索
        if !searchText.isEmpty {
            tasks = tasks.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return tasks
    }
    
    // 由于我们改用了ScrollView+LazyVStack，需要添加一个单独的删除方法
    private func deleteTask(_ task: Task) {
        // 使用标准中文标点符号
        print("TaskListView：删除任务 - ID：\(task.id)，标题：\(task.title)")
        taskStore.deleteTask(task)
    }
}

struct EnhancedTaskRow: View {
    var task: Task
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var categoryManager: CategoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 顶部区域：复选框、标题、优先级
            HStack(alignment: .top) {
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
                .padding(.top, 2) // 轻微调整复选框位置
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(task.isCompleted ? .gray : .primary)
                        .strikethrough(task.isCompleted)
                    
                    // 始终显示描述区域，如果没有描述则显示占位符
                    Text(task.description.isEmpty ? " " : task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(height: 18) // 固定高度
                }
                .padding(.vertical, 2)
                
                Spacer()
                
                priorityIcon(for: task.priority)
                    .padding(.trailing, 4)
            }
            
            // 底部区域：日期、分类、子任务
            HStack(spacing: 8) {
                // 日期区域 - 始终显示
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    
                    if let dueDate = task.dueDate {
                        Text(formattedDate(dueDate))
                            .font(.caption)
                            .foregroundColor(isPastDue(dueDate) && !task.isCompleted ? .red : .secondary)
                    } else {
                        Text(NSLocalizedString("无截止日期", comment: "No due date"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.7)
                    }
                }
                .frame(minWidth: 80, alignment: .leading)
                
                Spacer()
                
                // 分类标签 - 始终显示
                if let category = task.category {
                    categoryTag(for: category)
                } else if let customCategory = task.customCategory {
                    categoryTag(customCategory: customCategory)
                } else {
                    Text(NSLocalizedString("无分类", comment: "No category"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6).opacity(0.5))
                        .cornerRadius(4)
                }
                
                // 子任务计数
                if !task.subtasks.isEmpty {
                    Label("\(completedSubtasks(task))/\(task.subtasks.count)", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 6) // 统一垂直内边距
        .padding(.horizontal, 4) // 统一水平内边距
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
        .contentShape(Rectangle())
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func priorityIcon(for priority: TaskPriority) -> some View {
        switch priority {
        case .high:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
                .frame(width: 20, height: 20)
        case .medium:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
                .frame(width: 20, height: 20)
        case .low:
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
                .frame(width: 20, height: 20)
        }
    }
    
    private func categoryTag(for category: TaskCategory) -> some View {
        Text(category.localizedString)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(.systemGray6))
            .cornerRadius(4)
    }
    
    private func categoryTag(customCategory: CustomCategory) -> some View {
        Text(customCategory.name)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(CategoryManager.color(for: customCategory.colorName).opacity(0.15))
            )
            .foregroundColor(CategoryManager.color(for: customCategory.colorName))
    }
    
    private func completedSubtasks(_ task: Task) -> Int {
        return task.subtasks.filter { $0.isCompleted }.count
    }
    
    private func isPastDue(_ date: Date) -> Bool {
        return date < Date()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
            .environmentObject(CategoryManager())
    }
} 