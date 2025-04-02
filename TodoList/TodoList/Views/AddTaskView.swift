import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var categoryManager: CategoryManager
    @Binding var selectedTab: Int
    @Environment(\.presentationMode) var presentationMode
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: CustomCategory? = nil
    @State private var selectedPriority: TaskPriority = .medium
    @State private var hasDueDate = false
    @State private var dueDate = defaultDueDate()
    @State private var subtasks: [String] = [""]
    
    // 新分类相关状态
    @State private var showingAddCategorySheet = false
    @State private var newCategoryName = ""
    @State private var newCategoryColor = "blue"
    
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 任务标题
                VStack(alignment: .leading, spacing: 6) {
                    Text("任务名称")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("项目会议准备", text: $title)
                        .font(.system(size: 16))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 任务详情
                VStack(alignment: .leading, spacing: 6) {
                    Text("任务详情（可选）")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("准备明天的项目演示幻灯片，整理演示流程")
                                .font(.system(size: 16))
                                .foregroundColor(Color(.systemGray))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $description)
                            .font(.system(size: 16))
                            .frame(minHeight: 80)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            .background(Color.clear)
                    }
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                // 日期和时间
                HStack {
                    Text("日期")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $dueDate, displayedComponents: [.date])
                        .labelsHidden()
                        .onChange(of: dueDate) { _, _ in
                            hasDueDate = true
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                
                HStack {
                    Text("时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $dueDate, displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                        .onChange(of: dueDate) { _, _ in
                            hasDueDate = true
                        }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                
                // 优先级
                VStack(alignment: .leading, spacing: 10) {
                    Text("优先级")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        // 低优先级按钮
                        Button(action: {
                            selectedPriority = .low
                        }) {
                            VStack {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                                Text("低")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPriority == .low ? Color.green : Color(.systemGray4), lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedPriority == .low ? Color.green.opacity(0.1) : Color.clear)
                                    )
                                )
                        }
                        
                        // 中优先级按钮
                        Button(action: {
                            selectedPriority = .medium
                        }) {
                            VStack {
                                Image(systemName: "equal")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                                Text("中")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPriority == .medium ? Color.orange : Color(.systemGray4), lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedPriority == .medium ? Color.orange.opacity(0.1) : Color.clear)
                                    )
                                )
                        }
                        
                        // 高优先级按钮
                        Button(action: {
                            selectedPriority = .high
                        }) {
                            VStack {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                Text("高")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPriority == .high ? Color.red : Color(.systemGray4), lineWidth: 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedPriority == .high ? Color.red.opacity(0.1) : Color.clear)
                                    )
                                )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                
                // 标签
                VStack(alignment: .leading, spacing: 10) {
                    Text("分类")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // 显示所有可用分类
                            ForEach(categoryManager.categories) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(selectedCategory?.id == category.id ? .white : CategoryManager.color(for: category.colorName))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedCategory?.id == category.id ? 
                                                      CategoryManager.color(for: category.colorName) : 
                                                      CategoryManager.color(for: category.colorName).opacity(0.1))
                                        )
                                }
                            }
                            
                            // 添加新标签按钮
                            Button(action: {
                                // 显示添加新标签表单
                                showingAddCategorySheet = true
                            }) {
                                Text("+ 新分类")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(.horizontal)
                
                // 估计时间
                HStack {
                    Text("估计时间")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("暂未开放")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
                .padding(.horizontal)
                .padding(.vertical, 15)
                .opacity(0.6)
                
                Spacer()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("新建任务")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("取消") {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: Button("保存") {
                saveTask()
            }
            .disabled(title.isEmpty)
            .opacity(title.isEmpty ? 0.5 : 1)
        )
        .sheet(isPresented: $showingAddCategorySheet) {
            NavigationView {
                AddCategoryView(
                    newCategoryName: $newCategoryName,
                    newCategoryColor: $newCategoryColor,
                    onSave: { name, color in
                        // 添加新分类
                        categoryManager.addCategory(name: name, colorName: color)
                        
                        // 自动选择新添加的分类
                        if let newCategory = categoryManager.categories.last {
                            selectedCategory = newCategory
                        }
                        
                        // 重置表单
                        newCategoryName = ""
                        newCategoryColor = "blue"
                        
                        // 关闭表单
                        showingAddCategorySheet = false
                    }
                )
                .navigationTitle("添加新分类")
                .navigationBarItems(
                    leading: Button("取消") {
                        showingAddCategorySheet = false
                    }
                )
            }
        }
    }
    
    private func saveTask() {
        // 过滤掉空子任务
        let validSubtasks = subtasks.filter { !$0.isEmpty }
            .map { Subtask(title: $0) }
        
        // 根据自定义分类名匹配对应的 TaskCategory
        var category: TaskCategory? = nil
        if let selectedCategory = selectedCategory {
            // 将中文分类名映射到英文 TaskCategory
            switch selectedCategory.name {
            case "工作":
                category = .work
            case "个人": 
                category = .personal
            case "健康":
                category = .health
            case "重要":
                category = .important
            default:
                category = nil
            }
        }
        
        let newTask = Task(
            title: title,
            description: description,
            category: category, // 设置对应的 TaskCategory
            customCategory: selectedCategory, // 保留自定义分类
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority,
            subtasks: validSubtasks
        )
        
        taskStore.addTask(newTask)
        
        // 关闭视图
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
}

// 添加分类视图
struct AddCategoryView: View {
    @Binding var newCategoryName: String
    @Binding var newCategoryColor: String
    var onSave: (String, String) -> Void
    
    let availableColors = Array(CategoryManager.availableColors.keys).sorted()
    
    var body: some View {
        Form {
            Section(header: Text("分类信息")) {
                TextField("分类名称", text: $newCategoryName)
                    .padding(.vertical, 8)
            }
            
            Section(header: Text("选择颜色")) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(availableColors, id: \.self) { colorName in
                            Button(action: {
                                newCategoryColor = colorName
                            }) {
                                Circle()
                                    .fill(CategoryManager.color(for: colorName))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(newCategoryColor == colorName ? Color.white : Color.clear, lineWidth: 2)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(newCategoryColor == colorName ? Color.black : Color.clear, lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, -16)
            }
            
            Section {
                Button(action: {
                    // 只有当名称不为空时才保存
                    if !newCategoryName.isEmpty {
                        onSave(newCategoryName, newCategoryColor)
                    }
                }) {
                    Text("保存分类")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(newCategoryName.isEmpty ? Color.gray : CategoryManager.color(for: newCategoryColor))
                        )
                }
                .disabled(newCategoryName.isEmpty)
            }
        }
    }
}

struct AddTaskView_Previews: PreviewProvider {
    @State static var selectedTab = 0
    
    static var previews: some View {
        AddTaskView(selectedTab: $selectedTab)
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
            .environmentObject(CategoryManager())
    }
} 