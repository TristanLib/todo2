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
                    Text("主页")
                }
                .tag(0)
            
            TaskListView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("任务")
                }
                .tag(1)
            
            NavigationView {
                AddTaskView(selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                    .environment(\.symbolVariants, .fill)
                Text("新建")
            }
            .tag(4)
            
            FocusView()
                .tabItem {
                    Image(systemName: "timer")
                    Text("专注")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(3)
        }
        .accentColor(appSettings.accentColor.color)
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                TaskDetailView(task: task)
                    .navigationBarItems(trailing: Button("完成") {
                        showTaskDetail = nil
                    })
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFocusView)) { _ in
            selectedTab = 2 // 切换到专注标签
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
