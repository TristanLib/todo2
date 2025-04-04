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
        ZStack {
            // 背景颜色
            Color(UIColor.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // 自定义导航栏，减少顶部空间
                HStack {
                    Button(NSLocalizedString("取消", comment: "Cancel button")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(appSettings.accentColor.color)
                    
                    Spacer()
                    
                    Text(NSLocalizedString("新建任务", comment: "New task title"))
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(NSLocalizedString("保存", comment: "Save button")) {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : appSettings.accentColor.color)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // 表单区域，使用ScrollView替代Form以获得更好的样式控制
                ScrollView {
                    VStack(spacing: 16) {
                        // 基本信息卡片
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("基本信息", comment: "Basic info section header"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                // 任务名称
                                TextField(NSLocalizedString("任务名称", comment: "Task name field"), text: $title)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                
                                Divider()
                                
                                // 任务详情
                                ZStack(alignment: .topLeading) {
                                    if description.isEmpty {
                                        Text(NSLocalizedString("任务详情（可选）", comment: "Task description placeholder"))
                                            .foregroundColor(Color(.placeholderText))
                                            .padding(.top, 12)
                                            .padding(.leading, 16)
                                    }
                                    TextEditor(text: $description)
                                        .frame(minHeight: 60)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                }
                                .frame(minHeight: 60)
                                .background(Color.white)
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // 截止日期部分
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(NSLocalizedString("设置截止日期", comment: "Set due date toggle"), isOn: $hasDueDate.animation())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            
                            if hasDueDate {
                                VStack(spacing: 0) {
                                    DatePicker(NSLocalizedString("日期", comment: "Date picker label"), selection: $dueDate, displayedComponents: [.date])
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    
                                    Divider()
                                        .padding(.leading, 16)
                                    
                                    DatePicker(NSLocalizedString("时间", comment: "Time picker label"), selection: $dueDate, displayedComponents: [.hourAndMinute])
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                }
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 优先级部分
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("优先级", comment: "Priority section header"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            Picker(NSLocalizedString("优先级", comment: "Priority picker"), selection: $selectedPriority) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    Text(priority.localizedString).tag(priority)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // 分类部分
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("分类", comment: "Category section header"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // 显示现有分类
                                    ForEach(categoryManager.categories) { category in
                                        categoryChipButton(category: category)
                                    }
                                    
                                    // 添加新分类按钮
                                    Button {
                                        showingAddCategorySheet = true
                                    } label: {
                                        Label(NSLocalizedString("新分类", comment: "New category button"), systemImage: "plus.circle.fill")
                                            .font(.system(size: 14))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .foregroundColor(appSettings.accentColor.color)
                                            .background(
                                                Capsule().fill(appSettings.accentColor.color.opacity(0.1))
                                            )
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // 估计时间部分
                        VStack(alignment: .leading, spacing: 12) {
                            Text(NSLocalizedString("估计时间", comment: "Estimated time section header"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                            
                            Text(NSLocalizedString("暂未开放", comment: "Feature not available yet"))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal)
                        
                        // 底部间距
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            NavigationView {
                AddCategoryView(
                    newCategoryName: $newCategoryName,
                    newCategoryColor: $newCategoryColor,
                    onSave: { name, color in
                        categoryManager.addCategory(name: name, colorName: color)
                        if let newCategory = categoryManager.categories.last {
                            selectedCategory = newCategory // Select newly added category
                        }
                        newCategoryName = ""
                        newCategoryColor = "blue" // Reset form
                        showingAddCategorySheet = false
                    }
                )
                .navigationTitle(NSLocalizedString("添加新分类", comment: "Add new category title"))
                .navigationBarItems(leading: Button(NSLocalizedString("取消", comment: "Cancel button")) { showingAddCategorySheet = false }
                .foregroundColor(appSettings.accentColor.color))
            }
        }
    }
    
    // Helper to create category chip buttons
    private func categoryChipButton(category: CustomCategory) -> some View {
         Button {
             if selectedCategory?.id == category.id {
                 selectedCategory = nil // Deselect if tapped again
             } else {
                 selectedCategory = category
             }
         } label: {
             let isSelected = selectedCategory?.id == category.id
             let chipColor = CategoryManager.color(for: category.colorName)
             
             Text(category.localizedName)
                 .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                 .padding(.horizontal, 16)
                 .padding(.vertical, 6)
                 .foregroundColor(isSelected ? .white : chipColor)
                 .background(
                     Capsule().fill(isSelected ? chipColor : chipColor.opacity(0.15))
                 )
         }
    }
    
    private func saveTask() {
        // Map selected custom category to preset TaskCategory if name matches
        var presetCategory: TaskCategory? = nil
        if let custom = selectedCategory {
            switch custom.name {
                case TaskCategory.work.localizedString: presetCategory = .work
                case TaskCategory.personal.localizedString: presetCategory = .personal
                case TaskCategory.health.localizedString: presetCategory = .health
                case TaskCategory.important.localizedString: presetCategory = .important
                default: break
            }
        }

        let newTask = Task(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: presetCategory,
            customCategory: selectedCategory,
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority,
            subtasks: [] // Empty subtasks array
        )

        taskStore.addTask(newTask)
        presentationMode.wrappedValue.dismiss()
    }
}

// Preview Provider
struct AddTaskView_Previews: PreviewProvider {
    @State static var selectedTab = 0

    static var previews: some View {
        AddTaskView(selectedTab: $selectedTab)
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
            .environmentObject(CategoryManager())
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