import SwiftUI

// 箴言行视图
struct QuoteRowView: View {
    let quote: BilingualQuote
    @EnvironmentObject var appSettings: AppSettings
    
    // 当前是否为中文环境
    private var isChinese: Bool {
        if appSettings.language == .chineseSimplified {
            return true
        } else if appSettings.language == .system {
            // 获取系统语言
            let preferredLanguages = Locale.preferredLanguages
            return preferredLanguages.first?.starts(with: "zh") ?? false
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isChinese {
                Text(quote.chineseText)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("— \(quote.chineseAuthor)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text(quote.englishText)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("— \(quote.englishAuthor)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
