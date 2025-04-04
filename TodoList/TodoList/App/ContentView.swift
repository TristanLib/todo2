//
//  ContentView.swift
//  TodoList
//
//  Created by TristanLee on 2025/3/31.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedTab = 0
    @State private var showAddTask = false
    @State private var showTaskDetail: Task? = nil
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(NSLocalizedString("主页", comment: "Home tab title"))
                }
                .tag(0)
            
            TaskListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(NSLocalizedString("任务", comment: "Tasks tab title"))
                }
                .tag(1)
            
            Color.clear
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                        .environment(\.symbolVariants, .fill)
                    Text(NSLocalizedString("新建", comment: "New task tab title"))
                }
                .tag(2)
                .onChange(of: selectedTab) { oldValue, newValue in
                    if newValue == 2 {
                        showAddTask = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            selectedTab = oldValue
                        }
                    }
                }
            
            FocusView()
                .tabItem {
                    Image(systemName: "timer")
                    Text(NSLocalizedString("专注", comment: "Focus tab title"))
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text(NSLocalizedString("设置", comment: "Settings tab title"))
                }
                .tag(4)
        }
        .accentColor(appSettings.accentColor.color)
        .sheet(isPresented: $showAddTask) {
            NavigationView {
                AddTaskView(selectedTab: $selectedTab)
                    .onDisappear {
                        if selectedTab == 2 {
                            selectedTab = 0
                        }
                    }
            }
        }
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                TaskDetailView(task: task)
                    .navigationBarItems(trailing: Button("完成") {
                        showTaskDetail = nil
                    })
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFocusView)) { _ in
            selectedTab = 3 // 切换到专注标签
        }
        .onReceive(NotificationCenter.default.publisher(for: .openTaskDetails)) { notification in
            if let userInfo = notification.userInfo,
               let taskId = userInfo["taskId"] as? String,
               let taskUUID = UUID(uuidString: taskId),
               let task = taskStore.tasks.first(where: { $0.id == taskUUID }) {
                showTaskDetail = task
            } else {
                selectedTab = 1 // 如果找不到特定任务，则跳转到任务列表
            }
        }
    }
}

// TaskStore扩展，添加按ID查找任务的方法
extension TaskStore {
    func getTaskById(_ id: String) -> Task? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        return tasks.first { $0.id == uuid }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
}
