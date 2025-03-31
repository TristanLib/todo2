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
                    Label("主页", systemImage: "house.fill")
                }
                .tag(0)
            
            TaskListView()
                .tabItem {
                    Label("任务", systemImage: "list.bullet")
                }
                .tag(1)
            
            FocusView()
                .tabItem {
                    Label("专注", systemImage: "timer")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(3)
        }
        .accentColor(appSettings.accentColor.color)
        .overlay(
            Button(action: {
                showAddTask = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(appSettings.accentColor.color)
                    .clipShape(Circle())
                    .shadow(color: appSettings.accentColor.color.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .opacity(selectedTab == 0 || selectedTab == 1 ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .padding(.bottom, 70)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom),
            alignment: .bottom
        )
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
                .accentColor(appSettings.accentColor.color)
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
