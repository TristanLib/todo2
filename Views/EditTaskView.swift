import SwiftUI

struct EditTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskStore: TaskStore
    
    @Binding var task: Task
    @Binding var isEditing: Bool
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategory: TaskCategory?
    @State private var dueDate: Date
    @State private var hasDueDate: Bool
    @State private var priority: TaskPriority
    @State private var subtasks: [Subtask]
    @State private var newSubtask = ""
    
    init(task: Binding<Task>, isEditing: Binding<Bool>) {
        self._task = task
        self._isEditing = isEditing
        
        // Initialize state variables with the task's values
        _title = State(initialValue: task.wrappedValue.title)
        _description = State(initialValue: task.wrappedValue.description)
        _selectedCategory = State(initialValue: task.wrappedValue.category)
        _dueDate = State(initialValue: task.wrappedValue.dueDate ?? Date())
        _hasDueDate = State(initialValue: task.wrappedValue.dueDate != nil)
        _priority = State(initialValue: task.wrappedValue.priority)
        _subtasks = State(initialValue: task.wrappedValue.subtasks)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Information")) {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description")
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as TaskCategory?)
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as TaskCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Due Date")) {
                    Toggle("Add Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Subtasks")) {
                    ForEach(subtasks) { subtask in
                        HStack {
                            Button(action: {
                                toggleSubtask(subtask)
                            }) {
                                Image(systemName: subtask.isCompleted ? "checkmark.square" : "square")
                                    .foregroundColor(subtask.isCompleted ? .blue : .gray)
                            }
                            
                            Text(subtask.title)
                                .strikethrough(subtask.isCompleted)
                                .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                        }
                    }
                    .onDelete(perform: deleteSubtask)
                    
                    HStack {
                        TextField("Add subtask", text: $newSubtask)
                        
                        Button(action: addSubtask) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newSubtask.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isEditing = false
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func toggleSubtask(_ subtask: Subtask) {
        if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
            subtasks[index].isCompleted.toggle()
        }
    }
    
    private func addSubtask() {
        let subtask = Subtask(title: newSubtask)
        subtasks.append(subtask)
        newSubtask = ""
    }
    
    private func deleteSubtask(at indexSet: IndexSet) {
        subtasks.remove(atOffsets: indexSet)
    }
    
    private func saveTask() {
        var updatedTask = task
        updatedTask.title = title
        updatedTask.description = description
        updatedTask.category = selectedCategory
        updatedTask.dueDate = hasDueDate ? dueDate : nil
        updatedTask.priority = priority
        updatedTask.subtasks = subtasks
        
        taskStore.updateTask(updatedTask)
        task = updatedTask
        isEditing = false
    }
}

struct EditTaskView_Previews: PreviewProvider {
    static var previews: some View {
        EditTaskView(
            task: .constant(Task(
                title: "Example Task",
                description: "This is an example task description.",
                category: .work,
                dueDate: Date(),
                priority: .medium,
                subtasks: [
                    Subtask(title: "Subtask 1"),
                    Subtask(title: "Subtask 2", isCompleted: true)
                ]
            )),
            isEditing: .constant(true)
        )
        .environmentObject(TaskStore())
    }
} 