import SwiftUI

struct TaskDetailView: View {
    var task: Task
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var categoryManager: CategoryManager
    @State private var isEditing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    if let category = task.category {
                        Text(category.localizedString)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(categoryColor(for: category).opacity(0.15))
                            )
                            .foregroundColor(categoryColor(for: category))
                    } else if let customCategory = task.customCategory {
                        Text(customCategory.localizedName)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(CategoryManager.color(for: customCategory.colorName).opacity(0.15))
                            )
                            .foregroundColor(CategoryManager.color(for: customCategory.colorName))
                    }
                    
                    Spacer()
                    
                    Text(task.priority.localizedString)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(priorityColor(for: task.priority).opacity(0.15))
                        )
                        .foregroundColor(priorityColor(for: task.priority))
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
                            .foregroundColor(appSettings.accentColor.color)
                        Text(NSLocalizedString("截止日期: ", comment: "Due date label") + formattedDate(dueDate))
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack(spacing: 16) {
                    Button(action: {
                        var updatedTask = task
                        updatedTask.isCompleted.toggle()
                        taskStore.updateTask(updatedTask)
                    }) {
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : appSettings.accentColor.color)
                            Text(task.isCompleted ? 
                                NSLocalizedString("已完成", comment: "Completed status") : 
                                NSLocalizedString("标记为完成", comment: "Mark as complete"))
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        isEditing = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                                .foregroundColor(appSettings.accentColor.color)
                            Text(NSLocalizedString("编辑", comment: "Edit button"))
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if !task.subtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(NSLocalizedString("子任务", comment: "Subtasks section"))
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        ForEach(task.subtasks) { subtask in
                            Button(action: {
                                var updatedTask = task
                                if let index = updatedTask.subtasks.firstIndex(where: { $0.id == subtask.id }) {
                                    updatedTask.subtasks[index].isCompleted.toggle()
                                    taskStore.updateTask(updatedTask)
                                }
                            }) {
                                HStack {
                                    Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(subtask.isCompleted ? .green : .gray)
                                    Text(subtask.title)
                                        .strikethrough(subtask.isCompleted)
                                        .foregroundColor(subtask.isCompleted ? .gray : .primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    )
                }
            }
            .padding()
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: task)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
            return .red
        }
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

struct EditTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var categoryManager: CategoryManager
    
    var task: Task
    
    @State private var title: String
    @State private var description: String
    @State private var selectedCategoryTag: CategorySelectionTag?
    @State private var selectedPriority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    
    // Helper enum/struct to represent selection state unambiguously
    enum CategorySelectionTag: Hashable {
        case none
        case preset(TaskCategory)
        case custom(UUID)
    }
    
    // 设置默认截止日期为当天晚上10点
    private static func defaultDueDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // 获取当天日期的年、月、日部分
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        
        // 创建一个新的日期组件，设置时间为22:00:00
        var targetComponents = DateComponents()
        targetComponents.year = components.year
        targetComponents.month = components.month
        targetComponents.day = components.day
        targetComponents.hour = 22
        targetComponents.minute = 0
        targetComponents.second = 0
        
        // 将组件转换为日期
        return calendar.date(from: targetComponents) ?? now
    }
    
    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description)
        // Initialize the single state variable based on task's category
        if let customCategory = task.customCategory {
            _selectedCategoryTag = State(initialValue: .custom(customCategory.id))
        } else if let presetCategory = task.category {
            _selectedCategoryTag = State(initialValue: .preset(presetCategory))
        } else {
            _selectedCategoryTag = State(initialValue: .none)
        }
        _selectedPriority = State(initialValue: task.priority)
        _hasDueDate = State(initialValue: task.dueDate != nil)
        _dueDate = State(initialValue: task.dueDate ?? EditTaskView.defaultDueDate())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 自定义导航栏
            ZStack {
                // 左侧返回按钮
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14))
                            Text(NSLocalizedString("返回", comment: "Back button"))
                                .font(.system(size: 14))
                        }
                        .foregroundColor(appSettings.accentColor.color)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                    }
                    Spacer()
                }
                
                // 中间标题
                Text(NSLocalizedString("编辑任务", comment: "Edit task title"))
                    .font(.title2)
                    .fontWeight(.bold)
                
                // 右侧保存按钮
                HStack {
                    Spacer()
                    Button(action: saveTask) {
                        Text(NSLocalizedString("保存更改", comment: "Save changes button"))
                            .font(.system(size: 14))
                            .foregroundColor(title.isEmpty ? .gray : .white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(title.isEmpty ? Color.gray.opacity(0.3) : appSettings.accentColor.color)
                            )
                    }
                    .disabled(title.isEmpty)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            ScrollView {
                VStack(spacing: 24) {
                    // 任务标题和描述区域
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("任务标题")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("你需要做什么？", text: $title)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("描述")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("添加任务详情")
                                        .foregroundColor(.gray)
                                        .padding(.top, 16)
                                        .padding(.leading, 16)
                                }
                                
                                TextEditor(text: $description)
                                    .padding(8)
                                    .frame(minHeight: 120)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                    )
                    
                    // 分类和截止日期
                    HStack(spacing: 16) {
                        // 分类选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("分类")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Menu {
                                // 无分类选项
                                Button(action: {
                                    selectedCategoryTag = .none
                                }) {
                                    HStack {
                                        Text("无分类")
                                        if selectedCategoryTag == .none {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                // 预设分类
                                ForEach(TaskCategory.allCases, id: \.self) { category in
                                    Button(action: {
                                        selectedCategoryTag = .preset(category)
                                    }) {
                                        HStack {
                                            Text(category.localizedString)
                                            if selectedCategoryTag == .preset(category) {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                                
                                if !categoryManager.categories.isEmpty {
                                    Divider()
                                    
                                    // 自定义分类
                                    ForEach(categoryManager.categories) { category in
                                        // 排除与预设分类重复的自定义分类
                                        if !isDefaultCategory(category) {
                                            Button(action: {
                                                selectedCategoryTag = .custom(category.id)
                                            }) {
                                                HStack {
                                                    Text(category.name)
                                                    if selectedCategoryTag == .custom(category.id) {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(getCategoryName())
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .foregroundColor(.primary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        
                        // 截止日期选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("截止日期")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                DatePicker("", selection: $dueDate, displayedComponents: [.date])
                                    .labelsHidden()
                                    .onChange(of: dueDate) { _, _ in
                                        hasDueDate = true
                                    }
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    // 时间和优先级
                    HStack(spacing: 16) {
                        // 时间选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("时间")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                                .labelsHidden()
                                .onChange(of: dueDate) { _, _ in
                                    hasDueDate = true
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // 优先级选择器
                        VStack(alignment: .leading, spacing: 8) {
                            Text("优先级")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    Button(action: {
                                        selectedPriority = priority
                                    }) {
                                        Text(priorityLabel(for: priority))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .foregroundColor(selectedPriority == priority ? .white : priorityColor(for: priority))
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedPriority == priority ? priorityColor(for: priority) : priorityColor(for: priority).opacity(0.1))
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                    }
                    
                    // 底部空间
                    Color.clear
                        .frame(height: 0)
                    
                    // 底部空间，替代原来的保存按钮
                    Color.clear
                        .frame(height: 20)
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
    }
    
    private func saveTask() {
        var finalPresetCategory: TaskCategory? = nil
        var finalCustomCategory: CustomCategory? = nil

        switch selectedCategoryTag {
        case nil: // Explicitly handle the nil case for the Optional
            break // No category selected
        case .some(.none): // Handle the .none case inside the Optional
            break // No category selected
        case .some(.preset(let category)):
            finalPresetCategory = category
            // Optionally find the corresponding CustomCategory object if needed for consistency
            finalCustomCategory = categoryManager.categories.first { isPresetEquivalent($0, preset: category) }
        case .some(.custom(let id)):
            finalCustomCategory = categoryManager.categories.first { $0.id == id }
            // Check if this custom category corresponds to a preset one
            if let custom = finalCustomCategory, let preset = mapCustomToPreset(custom) {
                 finalPresetCategory = preset
             }
        }

        let updatedTask = Task(
            id: task.id,
            title: title,
            description: description,
            category: finalPresetCategory, // Use determined preset category
            customCategory: finalCustomCategory, // Use determined custom category
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority,
            isCompleted: task.isCompleted,
            subtasks: [], // 子任务功能已移除，传入空数组
            createdAt: task.createdAt
        )
        
        taskStore.updateTask(updatedTask)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func priorityLabel(for priority: TaskPriority) -> String {
        switch priority {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        }
    }
    
    private func priorityColor(for priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
    
    // 获取当前选中的分类名称
    private func getCategoryName() -> String {
        switch selectedCategoryTag {
        case nil: // Explicitly handle the nil case
            return NSLocalizedString("选择分类", comment: "Select category placeholder")
        case .some(.none): // Handle the .none case inside the Optional
            return NSLocalizedString("选择分类", comment: "Select category placeholder")
        case .some(.preset(let category)):
            return category.localizedString
        case .some(.custom(let id)):
            // Find the custom category name by ID
            return categoryManager.categories.first { $0.id == id }?.name ?? NSLocalizedString("选择分类", comment: "Select category placeholder")
        }
    }
    
    // 检查自定义分类是否与预设分类名称对应（用于排除重复显示）
    private func isDefaultCategory(_ customCategory: CustomCategory) -> Bool {
        // Compare against the localized names of the presets
        return TaskCategory.allCases.contains { $0.localizedString == customCategory.name }
    }

    // Helper to map a custom category back to a preset if its name matches
    private func mapCustomToPreset(_ customCategory: CustomCategory) -> TaskCategory? {
         return TaskCategory.allCases.first { $0.localizedString == customCategory.name }
     }
    
    // Helper to check if a custom category is equivalent to a preset one
    // (Might be needed if you store both separately but want them linked)
    private func isPresetEquivalent(_ customCategory: CustomCategory, preset: TaskCategory) -> Bool {
        return customCategory.name == preset.localizedString // Adjust logic if names don't guarantee equivalence
    }
}

struct TaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TaskDetailView(task: Task(title: "示例任务", description: "这是一个示例任务的描述"))
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
            .environmentObject(CategoryManager())
    }
} 