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
    @State private var isFormLoaded = false
    
    // 动画状态
    @State private var showInfoSection = false
    @State private var showCategorySection = false
    @State private var showDateSection = false
    @State private var showPrioritySection = false
    @State private var showSubtasksSection = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("任务信息")) {
                    TextField("标题", text: $title)
                        .slideIn(isPresented: showInfoSection, from: .leading)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("描述")
                                .foregroundColor(.gray.opacity(0.8))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                    }
                    .slideIn(isPresented: showInfoSection, from: .trailing)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(AnimationUtils.spring) {
                            showInfoSection = true
                        }
                    }
                }
                
                Section(header: Text("分类")) {
                    Picker("分类", selection: $selectedCategory) {
                        Text("无").tag(nil as TaskCategory?)
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as TaskCategory?)
                        }
                    }
                    .pickerStyle(.menu)
                    .slideIn(isPresented: showCategorySection, from: .trailing)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(AnimationUtils.spring) {
                            showCategorySection = true
                        }
                    }
                }
                
                Section(header: Text("截止日期")) {
                    Toggle("添加截止日期", isOn: $hasDueDate)
                        .slideIn(isPresented: showDateSection, from: .leading)
                    
                    if hasDueDate {
                        DatePicker("截止日期", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                            .slideIn(isPresented: showDateSection, from: .trailing)
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(AnimationUtils.spring) {
                            showDateSection = true
                        }
                    }
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue).tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                    .slideIn(isPresented: showPrioritySection, from: .bottom)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation(AnimationUtils.spring) {
                            showPrioritySection = true
                        }
                    }
                }
                
                Section(header: Text("子任务")) {
                    ForEach(subtasks) { subtask in
                        Text(subtask.title)
                            .slideIn(isPresented: showSubtasksSection, from: .trailing, delay: 0.1)
                    }
                    .onDelete(perform: deleteSubtask)
                    
                    HStack {
                        TextField("添加子任务", text: $newSubtask)
                        
                        Button(action: addSubtask) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .disabled(newSubtask.isEmpty)
                    }
                    .slideIn(isPresented: showSubtasksSection, from: .bottom)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(AnimationUtils.spring) {
                            showSubtasksSection = true
                        }
                    }
                }
            }
            .navigationTitle("新建任务")
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("保存") {
                    withAnimation {
                        saveTask()
                    }
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func addSubtask() {
        let subtask = Subtask(title: newSubtask)
        withAnimation(AnimationUtils.spring) {
            subtasks.append(subtask)
            newSubtask = ""
        }
    }
    
    private func deleteSubtask(at indexSet: IndexSet) {
        withAnimation(AnimationUtils.spring) {
            subtasks.remove(atOffsets: indexSet)
        }
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