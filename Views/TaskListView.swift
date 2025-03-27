import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var activeFilter: TaskFilter = .all
    @State private var searchText = ""
    @State private var showSearch = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showSearch {
                    searchBar
                }
                
                filterTabsBar
                
                if filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .navigationBarItems(trailing: searchButton)
        }
    }
    
    private var searchButton: some View {
        Button(action: {
            withAnimation {
                showSearch.toggle()
            }
        }) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
    }
    
    private var searchBar: some View {
        HStack {
            TextField("Search tasks...", text: $searchText)
                .padding(8)
                .padding(.horizontal, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            Button(action: {
                withAnimation {
                    searchText = ""
                    showSearch = false
                }
            }) {
                Text("Cancel")
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var filterTabsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation {
                            activeFilter = filter
                        }
                    }) {
                        Text(filter.title)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundColor(activeFilter == filter ? .blue : .gray)
                    }
                    .background(
                        VStack {
                            Spacer()
                            if activeFilter == filter {
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(.blue)
                                    .transition(.opacity)
                            } else {
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(.clear)
                            }
                        }
                    )
                }
            }
        }
        .background(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5))
                .offset(y: 20)
        )
    }
    
    private var taskList: some View {
        List {
            ForEach(filteredTasks) { task in
                NavigationLink(destination: TaskDetailView(task: task)) {
                    TaskItemRow(task: task) {
                        taskStore.toggleTaskCompletion(task)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
            }
            .onDelete { indexSet in
                taskStore.deleteTask(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.bottom, 10)
            
            Text("No tasks found")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Add a new task using the + button")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Properties
    
    var filteredTasks: [Task] {
        var tasks: [Task] = []
        
        switch activeFilter {
        case .all:
            tasks = taskStore.tasks
        case .today:
            tasks = taskStore.getTasksDueToday()
        case .completed:
            tasks = taskStore.getCompletedTasks()
        case .incomplete:
            tasks = taskStore.getIncompleteTasks()
        case .highPriority:
            tasks = taskStore.getTasks(for: .high)
        }
        
        if !searchText.isEmpty {
            tasks = tasks.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
        
        return tasks
    }
}

struct TaskItemRow: View {
    var task: Task
    var toggleAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Button(action: toggleAction) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    if let category = task.category {
                        Text(category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            
                            Text(dateFormatter.string(from: dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

enum TaskFilter: String, CaseIterable {
    case all
    case today
    case completed
    case incomplete
    case highPriority = "high_priority"
    
    var title: String {
        switch self {
        case .all:
            return "All"
        case .today:
            return "Today"
        case .completed:
            return "Completed"
        case .incomplete:
            return "Incomplete"
        case .highPriority:
            return "High Priority"
        }
    }
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView()
            .environmentObject(TaskStore())
    }
} 