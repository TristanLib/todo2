import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Environment(\.presentationMode) var presentationMode
    
    @State private var task: Task
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var isHeaderLoaded = false
    @State private var isDescriptionLoaded = false
    @State private var isSubtasksLoaded = false
    @State private var isMetadataLoaded = false
    @State private var isActionsLoaded = false
    
    init(task: Task) {
        _task = State(initialValue: task)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                taskHeader
                    .slideIn(isPresented: isHeaderLoaded, from: .top)
                
                if !task.description.isEmpty {
                    descriptionSection
                        .slideIn(isPresented: isDescriptionLoaded, from: .leading)
                }
                
                if !task.subtasks.isEmpty {
                    subtasksSection
                        .slideIn(isPresented: isSubtasksLoaded, from: .trailing)
                }
                
                metadataSection
                    .slideIn(isPresented: isMetadataLoaded, from: .leading)
                
                actionButtons
                    .popIn(isPresented: isActionsLoaded)
            }
            .padding()
        }
        .navigationTitle("任务详情")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: editButton)
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("删除任务"),
                message: Text("确定要删除此任务吗？此操作无法撤销。"),
                primaryButton: .destructive(Text("删除"), action: deleteTask),
                secondaryButton: .cancel(Text("取消"))
            )
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: $task, isEditing: $isEditing)
                .environmentObject(taskStore)
        }
        .onAppear {
            animateContent()
        }
    }
    
    private var editButton: some View {
        Button(action: {
            isEditing = true
        }) {
            Text("编辑")
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
            Text("描述")
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
            Text("子任务")
                .font(.headline)
            
            ForEach(task.subtasks) { subtask in
                HStack(spacing: 10) {
                    AnimatedCheckbox(isChecked: subtask.isCompleted) {
                        toggleSubtask(subtask)
                    }
                    
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
                Text("创建于 \(creationDateFormatter.string(from: task.createdAt))")
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
            }
            .font(.footnote)
            
            Label {
                Text(task.isCompleted ? "已完成" : "未完成")
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
            AnimatedButton(
                title: task.isCompleted ? "标记为未完成" : "标记为已完成",
                systemImage: task.isCompleted ? "circle" : "checkmark.circle.fill",
                color: .blue
            ) {
                toggleCompletion()
            }
            
            AnimatedButton(
                title: "删除",
                systemImage: "trash",
                color: .red
            ) {
                showingDeleteAlert = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func animateContent() {
        withAnimation(AnimationUtils.spring.delay(0.1)) {
            isHeaderLoaded = true
        }
        
        withAnimation(AnimationUtils.spring.delay(0.2)) {
            isDescriptionLoaded = true
        }
        
        withAnimation(AnimationUtils.spring.delay(0.3)) {
            isSubtasksLoaded = true
        }
        
        withAnimation(AnimationUtils.spring.delay(0.4)) {
            isMetadataLoaded = true
        }
        
        withAnimation(AnimationUtils.spring.delay(0.5)) {
            isActionsLoaded = true
        }
    }
    
    private func toggleCompletion() {
        withAnimation(AnimationUtils.spring) {
            task.isCompleted.toggle()
            taskStore.updateTask(task)
        }
    }
    
    private func toggleSubtask(_ subtask: Subtask) {
        if let index = task.subtasks.firstIndex(where: { $0.id == subtask.id }) {
            withAnimation(AnimationUtils.spring) {
                task.subtasks[index].isCompleted.toggle()
                taskStore.updateTask(task)
            }
        }
    }
    
    private func deleteTask() {
        taskStore.deleteTask(id: task.id)
        presentationMode.wrappedValue.dismiss()
    }
    
    private var priorityText: String {
        switch task.priority {
        case .low:
            return "低优先级"
        case .medium:
            return "中优先级"
        case .high:
            return "高优先级"
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
            return .purple
        case .health:
            return .green
        case .important:
            return .orange
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
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TaskDetailView(task: Task(title: "示例任务", description: "这是一个示例任务描述"))
                .environmentObject(TaskStore())
        }
    }
} 