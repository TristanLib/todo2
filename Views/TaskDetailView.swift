import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var task: Task
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    init(task: Task) {
        _task = State(initialValue: task)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                taskHeader
                
                if !task.description.isEmpty {
                    descriptionSection
                }
                
                if !task.subtasks.isEmpty {
                    subtasksSection
                }
                
                metadataSection
                
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: editButton)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Task"),
                message: Text("Are you sure you want to delete this task? This cannot be undone."),
                primaryButton: .destructive(Text("Delete"), action: deleteTask),
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: $task, isEditing: $isEditing)
                .environmentObject(taskStore)
        }
    }
    
    private var editButton: some View {
        Button(action: {
            isEditing = true
        }) {
            Text("Edit")
                .foregroundColor(.blue)
        }
    }
    
    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let category = task.category {
                    Text(category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor(for: category))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            HStack {
                Label {
                    Text(priorityText)
                        .foregroundColor(.secondary)
                } icon: {
                    Image(systemName: "flag.fill")
                        .foregroundColor(priorityColor)
                }
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    Label {
                        Text(dateFormatter.string(from: dueDate))
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                    }
                }
            }
            .font(.subheadline)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Description")
                .font(.headline)
            
            Text(task.description)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Subtasks")
                .font(.headline)
            
            ForEach(task.subtasks) { subtask in
                HStack(spacing: 10) {
                    Button(action: {
                        toggleSubtask(subtask)
                    }) {
                        ZStack {
                            Circle()
                                .strokeBorder(subtask.isCompleted ? Color.blue : Color.gray, lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            if subtask.isCompleted {
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
                    
                    Text(subtask.title)
                        .strikethrough(subtask.isCompleted)
                        .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text("Created on \(creationDateFormatter.string(from: task.createdAt))")
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
            }
            .font(.footnote)
            
            Label {
                Text(task.isCompleted ? "Completed" : "Not completed")
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .font(.footnote)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var actionButtons: some View {
        HStack {
            Button(action: toggleCompletion) {
                HStack {
                    Image(systemName: task.isCompleted ? "circle" : "checkmark.circle.fill")
                    Text(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleCompletion() {
        task.isCompleted.toggle()
        taskStore.updateTask(task)
    }
    
    private func toggleSubtask(_ subtask: Subtask) {
        if let index = task.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            task.subtasks[index].isCompleted.toggle()
            taskStore.updateTask(task)
        }
    }
    
    private func deleteTask() {
        taskStore.deleteTask(id: task.id)
        presentationMode.wrappedValue.dismiss()
    }
    
    private var priorityText: String {
        switch task.priority {
        case .low:
            return "Low Priority"
        case .medium:
            return "Medium Priority"
        case .high:
            return "High Priority"
        }
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
    
    private func categoryColor(for category: TaskCategory) -> Color {
        switch category {
        case .work:
            return .blue
        case .personal:
            return .green
        case .health:
            return .orange
        case .important:
            return .red
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var creationDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskDetailView(task: Task(
                title: "Example Task",
                description: "This is an example task description.",
                category: .work,
                dueDate: Date(),
                priority: .medium,
                subtasks: [
                    Subtask(title: "Subtask 1"),
                    Subtask(title: "Subtask 2", isCompleted: true)
                ]
            ))
            .environmentObject(TaskStore())
        }
    }
} 