import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    @State private var showRestartAlert = false

    var body: some View {
        Form { // 使用 Form 提供标准设置外观
            Section(header: Text(NSLocalizedString("语言设置", comment: "Language settings section header"))) {
                Picker(NSLocalizedString("应用语言", comment: "App language picker label"), selection: $appSettings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .onChange(of: appSettings.language) { newLanguage in
                    // 应用语言设置
                    applyLanguageSetting(newLanguage)
                    // 提示用户可能需要重启
                    showRestartAlert = true 
                }
            }
            
            // 可以添加其他偏好设置，例如时间格式等
            // Section(header: Text(NSLocalizedString("时间格式", comment: "Time format section header"))) {
            //     // ... 时间格式选择器 ...
            // }
        }
        .navigationTitle(NSLocalizedString("偏好设置", comment: "Preferences view navigation title"))
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showRestartAlert) {
             Alert(
                 title: Text(NSLocalizedString("语言已更改", comment: "Language changed alert title")),
                 message: Text(NSLocalizedString("您可能需要重新启动应用以使更改完全生效。", comment: "Language change restart required message")),
                 dismissButton: .default(Text(NSLocalizedString("好的", comment: "OK button")))
             )
         }
    }
    
    // 应用语言设置到 UserDefaults
    private func applyLanguageSetting(_ language: AppLanguage) {
        if let languageCode = language.languageCode {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        } else {
            // 如果选择“跟随系统”，则移除设置，让系统决定
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        // 注意：这种方式通常需要重启应用才能完全生效
        // UserDefaults.standard.synchronize() // 可选，有时有助于立即生效，但非必需
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { // 包裹在 NavigationView 中以便预览标题
            PreferencesView()
                .environmentObject(AppSettings()) // 提供预览所需的环境对象
        }
    }
}
