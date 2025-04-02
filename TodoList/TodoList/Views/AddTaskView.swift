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
        NavigationView {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("任务名称", text: $title)
                    
                    // Use TextEditor directly for multi-line description
                    ZStack(alignment: .topLeading) {
                         if description.isEmpty {
                             Text("任务详情（可选）")
                                 .foregroundColor(Color(.placeholderText))
                                 .padding(.top, 8)
                                 .padding(.leading, 5) // Adjust padding slightly
                         }
                         TextEditor(text: $description)
                            .frame(minHeight: 80) // Keep minHeight
                     }
                }

                Section {
                    Toggle("设置截止日期", isOn: $hasDueDate.animation())
                    
                    if hasDueDate {
                        DatePicker("日期", selection: $dueDate, displayedComponents: [.date])
                        DatePicker("时间", selection: $dueDate, displayedComponents: [.hourAndMinute])
                    }
                }
                
                Section(header: Text("优先级")) {
                    Picker("优先级", selection: $selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priorityLabel(for: priority)).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("分类")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // Uncategorized option? Maybe add later if needed.
                            
                            // Show existing categories
                            ForEach(categoryManager.categories) { category in
                                categoryChipButton(category: category)
                            }

                            // Add New Category Button
                            Button {
                                showingAddCategorySheet = true
                            } label: {
                                Label("新分类", systemImage: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .foregroundColor(appSettings.accentColor.color)
                                    .background(
                                        Capsule().fill(appSettings.accentColor.color.opacity(0.1))
                                    )
                            }
                        }
                        .padding(.vertical, 5) // Add padding inside scrollview
                    }
                    // Consider removing horizontal padding if Form handles it
                }
                
                // Subtasks Section (assuming simple string array for now)
                Section(header: Text("子任务")) {
                    ForEach($subtasks.indices, id: \.self) { index in
                         HStack {
                            TextField("子任务 \\(index + 1)", text: $subtasks[index])
                            // Button to remove subtask? Maybe add later.
                         }
                    }
                    
                    Button {
                         subtasks.append("") // Add a new empty subtask field
                    } label: {
                         Label("添加子任务", systemImage: "plus")
                    }
                    .foregroundColor(appSettings.accentColor.color)
                }

                // Estimate Time Section (Placeholder)
                Section(header: Text("估计时间")) {
                     Text("暂未开放")
                         .foregroundColor(.secondary)
                }
            }
            .navigationTitle("新建任务")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(appSettings.accentColor.color), // Apply accent color
                
                trailing: Button("保存") {
                    saveTask()
                }
                .disabled(title.isEmpty)
                .foregroundColor(title.isEmpty ? .gray : appSettings.accentColor.color) // Apply accent color / gray
            )
            .sheet(isPresented: $showingAddCategorySheet) {
                // Add Category Sheet View (ensure it's wrapped in NavigationView if needed)
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
                    .navigationTitle("添加新分类")
                    .navigationBarItems(leading: Button("取消") { showingAddCategorySheet = false }
                    .foregroundColor(appSettings.accentColor.color)) // Apply accent color
                 }
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
             
             Text(category.name)
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
        let validSubtasks = subtasks
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // Trim whitespace
            .filter { !$0.isEmpty }
            .map { Subtask(title: $0) }
        
        // Map selected custom category to preset TaskCategory if name matches
        // This logic might need refinement depending on how you want to handle preset vs custom
        var presetCategory: TaskCategory? = nil
        if let custom = selectedCategory {
            switch custom.name {
                case TaskCategory.work.localizedName: presetCategory = .work
                case TaskCategory.personal.localizedName: presetCategory = .personal
                case TaskCategory.health.localizedName: presetCategory = .health
                case TaskCategory.important.localizedName: presetCategory = .important
                default: break
            }
        }

        let newTask = Task(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines), // Trim title
            description: description.trimmingCharacters(in: .whitespacesAndNewlines), // Trim description
            category: presetCategory, // Use mapped preset category if available
            customCategory: selectedCategory, // Always save the selected custom category ID/object
            dueDate: hasDueDate ? dueDate : nil,
            priority: selectedPriority,
            subtasks: validSubtasks
        )

        taskStore.addTask(newTask)
        presentationMode.wrappedValue.dismiss()
    }
    
    // Helper to get priority label (ensure TaskPriority is CaseIterable)
    private func priorityLabel(for priority: TaskPriority) -> String {
        switch priority {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }
}

// Assume TaskPriority conforms to CaseIterable & Identifiable
// enum TaskPriority: String, CaseIterable, Identifiable {
//     case low, medium, high
//     var id: String { self.rawValue }
// }

// Preview Provider might need adjustment if AddTaskView depends on NavigationView from parent
struct AddTaskView_Previews: PreviewProvider {
    @State static var selectedTab = 0 // Example binding

    static var previews: some View {
        AddTaskView(selectedTab: $selectedTab)
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
            .environmentObject(CategoryManager())
    }
}

// Assume AddCategoryView exists and works with the bindings
// struct AddCategoryView: View { ... }

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