import SwiftUI

struct AddQuickTaskView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var categoryManager: CategoryManager
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject var quickTaskManager = QuickTaskManager.shared
    
    @State private var title = ""
    @State private var selectedCategory: CustomCategory? = nil
    @State private var selectedPriority: TaskPriority = .medium
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor = "blue"
    
    var editingTask: QuickTask?
    var onSave: ((QuickTask) -> Void)?
    
    // 可用的图标列表
    private let availableIcons = [
        "star.fill", "brain.head.profile", "figure.strengthtraining.traditional", "book.fill", "figure.run",
        "heart.fill", "cup.and.saucer.fill", "fork.knife", "cart.fill", "bag.fill",
        "house.fill", "car.fill", "airplane", "bus", "tram.fill",
        "laptopcomputer", "desktopcomputer", "gamecontroller.fill", "tv.fill", "headphones",
        "moon.stars.fill", "sun.max.fill", "cloud.fill", "leaf.fill", "flame.fill"
    ]
    
    // 可用的颜色列表
    private let availableColors = Array(CategoryManager.availableColors.keys).sorted()
    
    init(editingTask: QuickTask? = nil, onSave: ((QuickTask) -> Void)? = nil) {
        self.editingTask = editingTask
        self.onSave = onSave
        
        // 如果是编辑模式，初始化状态变量
        if let task = editingTask {
            _title = State(initialValue: task.title)
            _selectedCategory = State(initialValue: task.category)
            _selectedPriority = State(initialValue: task.priority)
            _selectedIcon = State(initialValue: task.iconName)
            _selectedColor = State(initialValue: task.colorName)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 基本信息部分
                Section(header: Text(NSLocalizedString("基本信息", comment: "Basic info section"))) {
                    TextField(NSLocalizedString("任务名称", comment: "Task name field"), text: $title)
                        .padding(.vertical, 8)
                    
                    // 优先级选择
                    HStack {
                        Text(NSLocalizedString("优先级", comment: "Priority label"))
                        Spacer()
                        Picker("", selection: $selectedPriority) {
                            ForEach(TaskPriority.allCases, id: \.self) { priority in
                                Text(priority.localizedString)
                                    .foregroundColor(priority.color)
                                    .tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 200)
                    }
                    .padding(.vertical, 8)
                }
                
                // 分类选择部分
                Section(header: Text(NSLocalizedString("分类", comment: "Category section"))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // 无分类选项
                            Button {
                                selectedCategory = nil
                            } label: {
                                Text(NSLocalizedString("无分类", comment: "No category option"))
                                    .font(.system(size: 14, weight: selectedCategory == nil ? .semibold : .regular))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 6)
                                    .foregroundColor(selectedCategory == nil ? .white : .gray)
                                    .background(
                                        Capsule().fill(selectedCategory == nil ? Color.gray : Color.gray.opacity(0.15))
                                    )
                            }
                            
                            // 显示现有分类
                            ForEach(categoryManager.categories) { category in
                                Button {
                                    if selectedCategory?.id == category.id {
                                        selectedCategory = nil // 再次点击取消选择
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
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // 图标选择部分
                Section(header: Text(NSLocalizedString("选择图标", comment: "Icon selection section"))) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 15), count: 5), spacing: 15) {
                        ForEach(availableIcons, id: \.self) { iconName in
                            Button {
                                selectedIcon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.system(size: 24))
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(selectedIcon == iconName ? .white : CategoryManager.color(for: selectedColor))
                                    .background(
                                        Circle()
                                            .fill(selectedIcon == iconName ? CategoryManager.color(for: selectedColor) : CategoryManager.color(for: selectedColor).opacity(0.1))
                                    )
                            }
                            .buttonStyle(PlainButtonStyle()) // 添加这一行以确保按钮可以正常响应点击
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 颜色选择部分
                Section(header: Text(NSLocalizedString("选择颜色", comment: "Color selection section"))) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { colorName in
                                Button {
                                    selectedColor = colorName
                                } label: {
                                    Circle()
                                        .fill(CategoryManager.color(for: colorName))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == colorName ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                        .overlay(
                                            selectedColor == colorName ?
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.system(size: 14, weight: .bold))
                                            : nil
                                        )
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                }
                                .buttonStyle(PlainButtonStyle()) // 添加这一行以确保按钮可以正常响应点击
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(editingTask == nil ? 
                            NSLocalizedString("添加快捷任务", comment: "Add quick task title") : 
                            NSLocalizedString("编辑快捷任务", comment: "Edit quick task title"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("取消", comment: "Cancel button")) {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(appSettings.accentColor.color),
                
                trailing: Button(NSLocalizedString("保存", comment: "Save button")) {
                    saveQuickTask()
                }
                .disabled(title.isEmpty)
                .foregroundColor(title.isEmpty ? .gray : appSettings.accentColor.color)
            )
        }
    }
    
    private func saveQuickTask() {
        let quickTask = QuickTask(
            id: editingTask?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            priority: selectedPriority,
            iconName: selectedIcon,
            colorName: selectedColor
        )
        
        if let onSave = onSave {
            onSave(quickTask)
        } else if editingTask != nil {
            quickTaskManager.updateQuickTask(quickTask)
        } else {
            quickTaskManager.addQuickTask(quickTask)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct AddQuickTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AddQuickTaskView()
            .environmentObject(CategoryManager())
            .environmentObject(AppSettings())
    }
}
