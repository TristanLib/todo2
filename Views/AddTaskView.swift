import SwiftUI

struct AddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskStore: TaskStore
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TaskCategory?
    @State private var dueDate = Date()
    @State private var hasDueDate = false
    @State private var priority: TaskPriority = .medium
    @State private var subtasks: [Subtask] = []
    @State private var newSubtask = ""
    
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
                        Text(subtask.title)
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
            .navigationTitle("New Task")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(title.isEmpty)
            )
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
        let task = Task(
            title: title,
            description: description,
            category: selectedCategory,
            dueDate: hasDueDate ? dueDate : nil,
            priority: priority,
            isCompleted: false,
            subtasks: subtasks
        )
        
        taskStore.addTask(task)
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddTaskView()
            .environmentObject(TaskStore())
    }
} 