import SwiftUI

struct TaskDetailView: View {
    var task: Task
    @EnvironmentObject var taskStore: TaskStore
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    if let category = task.category {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    Text(task.priority.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                }
                
                Text(task.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                if let dueDate = task.dueDate {
                    HStack {
                        Image(systemName: "calendar")
                        Text("截止日期: \(formattedDate(dueDate))")
                    }
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Button(action: {
                        var updatedTask = task
                        updatedTask.isCompleted.toggle()
                        taskStore.updateTask(updatedTask)
                    }) {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            Text(task.isCompleted ? "已完成" : "标记为完成")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        isEditing = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("编辑")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                
                if !task.subtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("子任务")
                            .font(.headline)
                        
                        ForEach(task.subtasks) { subtask in
                            HStack {
                                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(subtask.isCompleted ? .green : .gray)
                                Text(subtask.title)
                                    .strikethrough(subtask.isCompleted)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: task)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct EditTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskStore: TaskStore
    
    var task: Task
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: TaskCategory?
    @State private var selectedPriority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    
    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        _selectedCategory = State(initialValue: task.category)
        _selectedPriority = State(initialValue: task.priority)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("标题", text: $title)
                    
                    TextField("描述", text: $description)
                }
                
                Section(header: Text("分类")) {
                    Picker("选择分类", selection: $selectedCategory) {
                        Text("无分类").tag(nil as TaskCategory?)
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as TaskCategory?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("优先级")) {
                    Picker("选择优先级", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("截止日期")) {
                    Toggle("设置截止日期", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "截止日期",
                            selection: $dueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                }
            }
            .navigationTitle("编辑任务")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.category = selectedCategory
        updatedTask.priority = selectedPriority
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        
        taskStore.updateTask(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }
} 