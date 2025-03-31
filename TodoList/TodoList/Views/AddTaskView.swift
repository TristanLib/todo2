import SwiftUI

struct AddTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskStore: TaskStore
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TaskCategory? = nil
    @State private var selectedPriority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
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
            .navigationTitle("添加任务")
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
        let newTask = Task(
            title: title,
            description: description,
            category: selectedCategory,
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority
        )
        
        taskStore.addTask(newTask)
        presentationMode.wrappedValue.dismiss()
    }
} 