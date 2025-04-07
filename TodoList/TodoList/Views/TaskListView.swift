import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var selectedFilter: TaskFilter
    @State private var searchText = ""
    
    enum TaskFilter {
        case all, active, completed
    }
    
    init(initialFilter: TaskFilter = .all) {
        _selectedFilter = State(initialValue: initialFilter)
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
                    EditButton()
                        .foregroundColor(appSettings.accentColor.color)
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
        List {
            ForEach(filteredTasks) { task in
                NavigationLink(destination: TaskDetailView(task: task)) {
                    EnhancedTaskRow(task: task)
                }
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteTask)
        }
        .listStyle(PlainListStyle())
        .padding(.horizontal)
        .background(Color(.systemGroupedBackground))
    }
    
    private var filteredTasks: [Task] {
        var tasks = taskStore.tasks
        
        // 应用过滤器
        switch selectedFilter {
        case .all: break
        case .active:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
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
    
    private func deleteTask(at offsets: IndexSet) {
        print("TaskListView: 开始删除任务，索引: \(offsets)")
        DispatchQueue.main.async {
            for index in offsets {
                let task = self.filteredTasks[index]
                print("TaskListView: 删除任务 - ID: \(task.id), 标题: \(task.title)")
                self.taskStore.deleteTask(task)
            }
        }
    }
}

struct EnhancedTaskRow: View {
    var task: Task
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var categoryManager: CategoryManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
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
                }
                .padding(.vertical, 2)
                
                Spacer()
                
                priorityIcon(for: task.priority)
                    .padding(.trailing, 4)
            }
            
            HStack {
                if let dueDate = task.dueDate {
                    Label(
                        formattedDate(dueDate),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(isPastDue(dueDate) && !task.isCompleted ? .red : .secondary)
                }
                
                Spacer()
                
                if let category = task.category {
                    categoryTag(for: category)
                } else if let customCategory = task.customCategory {
                    categoryTag(customCategory: customCategory)
                }
                
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