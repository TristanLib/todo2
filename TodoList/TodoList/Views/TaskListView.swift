import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    
    var body: some View {
        NavigationView {
            List {
                ForEach(taskStore.tasks) { task in
                    TaskRow(task: task)
                }
                .onDelete(perform: deleteTask)
            }
            .navigationTitle("任务列表")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteTask(at offsets: IndexSet) {
        taskStore.deleteTask(at: offsets)
    }
}

struct TaskRow: View {
    var task: Task
    @EnvironmentObject var taskStore: TaskStore
    
    var body: some View {
        HStack {
            Button(action: {
                taskStore.toggleTaskCompletion(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let dueDate = task.dueDate {
                    Text("截止日期: \(formattedDate(dueDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let category = task.category {
                    Text("分类: \(category.rawValue)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 5)
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