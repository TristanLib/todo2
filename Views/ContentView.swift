import SwiftUI

struct ContentView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedTab = 0
    @State private var showAddTask = false
    
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
            .opacity(selectedTab != 3 ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .padding(.bottom, 70)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom),
            alignment: .bottom
        )
        .sheet(isPresented: $showAddTask) {
            AddTaskView()
                .accentColor(appSettings.accentColor.color)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(TaskStore())
            .environmentObject(AppSettings())
    }
} 