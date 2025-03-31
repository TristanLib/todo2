import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @Binding var selectedTab: Int
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: TaskCategory? = nil
    @State private var selectedPriority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    var body: some View {
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
            
            Section {
                HStack {
                    Button(action: cancel) {
                        Text("取消")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    Button(action: saveTask) {
                        Text("保存")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(title.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .navigationTitle("添加任务")
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
        
        // 重置表单
        title = ""
        description = ""
        selectedCategory = nil
        selectedPriority = .medium
        hasDueDate = false
        dueDate = Date()
        
        // 切换到首页
        selectedTab = 0
    }
    
    private func cancel() {
        // 切换到首页
        selectedTab = 0
    }
} 