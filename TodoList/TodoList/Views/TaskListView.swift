import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    
    enum TaskFilter {
        case all, active, completed
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
            .navigationTitle("任务列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .foregroundColor(appSettings.accentColor.color)
                }
            }
        }
    }
    
    private var filterTabBar: some View {
        HStack(spacing: 0) {
            filterTab(title: "全部", filter: .all)
            filterTab(title: "进行中", filter: .active)
            filterTab(title: "已完成", filter: .completed)
        }
        .background(Color(.systemBackground))
    }
    
    private func filterTab(title: String, filter: TaskFilter) -> some View {
        let isSelected = filter == selectedFilter
        
        return Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedFilter = filter
            }
        }) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? appSettings.accentColor.color : .gray)
                
                // 活动指示器
                Rectangle()
                    .fill(isSelected ? appSettings.accentColor.color : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索任务...", text: $searchText)
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
            return searchText.isEmpty ? "你的任务列表是空的" : "没有找到匹配的任务"
        case .active:
            return "没有进行中的任务"
        case .completed:
            return "没有完成的任务"
        }
    }
    
    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                NavigationLink(destination: TaskDetailView(task: task)) {
                    EnhancedTaskRow(task: task)
                        .padding(.vertical, 8)
                }
                .listRowBackground(Color(.systemBackground))
            }
            .onDelete(perform: deleteTask)
        }
        .listStyle(InsetGroupedListStyle())
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                }
                
                Spacer()
                
                priorityIcon(for: task.priority)
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
        case .medium:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16))
        case .low:
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
        }
    }
    
    private func categoryTag(for category: TaskCategory) -> some View {
        Text(category.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color(.systemGray6))
            .cornerRadius(4)
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
    }
} 