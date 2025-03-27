import SwiftUI

struct HomeView: View {
    @EnvironmentObject var taskStore: TaskStore
    @State private var selectedCategory: TaskCategory? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    progressSection
                    
                    categorySection
                    
                    todayTasksSection
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarItems(trailing: Button(action: {}) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            })
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Progress")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(completedTodayTasks.count)/\(todayTasks.count) Tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressBar(value: progressValue)
                .frame(height: 8)
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Categories")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    
                    ForEach(TaskCategory.allCases, id: \.self) { category in
                        CategoryChip(
                            title: category.rawValue,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Tasks")
                .font(.title3)
                .fontWeight(.bold)
            
            if filteredTasks.isEmpty {
                emptyTasksView
            } else {
                ForEach(filteredTasks) { task in
                    TaskRow(task: task) {
                        taskStore.toggleTaskCompletion(task)
                    }
                }
            }
        }
    }
    
    private var emptyTasksView: some View {
        VStack(spacing: 10) {
            Image(systemName: "checklist")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No tasks for today")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap the + button to add a new task")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
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

struct ProgressBar: View {
    var value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color(.systemGray5))
                    .cornerRadius(5)
                
                Rectangle()
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width))
                    .foregroundColor(.blue)
                    .cornerRadius(5)
            }
        }
    }
}

struct CategoryChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct TaskRow: View {
    var task: Task
    var toggleAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: toggleAction) {
                ZStack {
                    Circle()
                        .strokeBorder(task.isCompleted ? Color.blue : Color.gray.opacity(0.5), lineWidth: 2)
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
            
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 10) {
                    if let category = task.category {
                        Text(category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
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
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TaskStore())
    }
} 