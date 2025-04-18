import SwiftUI

// 箴言列表管理界面
struct QuoteListView: View {
    @EnvironmentObject var quoteManager: QuoteManager
    @EnvironmentObject var appSettings: AppSettings
    @State private var showAddQuoteSheet = false
    @State private var showingDefaultQuotes = false
    @State private var searchText = ""
    
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
    
    // 过滤后的箴言列表
    var filteredQuotes: [BilingualQuote] {
        let quotes = showingDefaultQuotes ? quoteManager.getDefaultQuotes() : quoteManager.getCustomQuotes()
        if searchText.isEmpty {
            return quotes
        } else {
            return quotes.filter { quote in
                quote.chineseText.localizedCaseInsensitiveContains(searchText) ||
                quote.englishText.localizedCaseInsensitiveContains(searchText) ||
                quote.chineseAuthor.localizedCaseInsensitiveContains(searchText) ||
                quote.englishAuthor.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            SearchBar(text: $searchText, placeholder: NSLocalizedString("搜索箴言...", comment: "Search quotes placeholder"))
                .padding(.horizontal)
                .padding(.top, 8)
            
            // 分段控制器
            Picker("", selection: $showingDefaultQuotes) {
                Text(NSLocalizedString("自定义箴言", comment: "Custom quotes tab"))
                    .tag(false)
                Text(NSLocalizedString("默认箴言", comment: "Default quotes tab"))
                    .tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if filteredQuotes.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "text.quote")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(showingDefaultQuotes 
                         ? NSLocalizedString("没有找到匹配的默认箴言", comment: "No matching default quotes")
                         : NSLocalizedString("没有找到匹配的自定义箴言", comment: "No matching custom quotes"))
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    if !showingDefaultQuotes && searchText.isEmpty {
                        Button(action: {
                            showAddQuoteSheet = true
                        }) {
                            Text(NSLocalizedString("添加第一条箴言", comment: "Add first quote button"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                // 箴言列表
                List {
                    ForEach(filteredQuotes) { quote in
                        QuoteRow(quote: quote)
                            .contentShape(Rectangle())
                            .background(NavigationLink("", destination: {
                                if showingDefaultQuotes {
                                    QuoteDetailView(quote: quote)
                                        .environmentObject(appSettings)
                                } else {
                                    QuoteEditView(mode: .edit, quote: quote)
                                        .environmentObject(quoteManager)
                                        .environmentObject(appSettings)
                                }
                            }).opacity(0))
                    }
                    .onDelete { indexSet in
                        if !showingDefaultQuotes {
                            deleteQuotes(at: indexSet)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationTitle(NSLocalizedString("箴言管理", comment: "Quote management title"))
        .navigationBarItems(
            trailing: !showingDefaultQuotes ? Button(action: {
                showAddQuoteSheet = true
            }) {
                Image(systemName: "plus")
            } : nil
        )
        .sheet(isPresented: $showAddQuoteSheet) {
            QuoteEditView(mode: .add)
                .environmentObject(quoteManager)
                .environmentObject(appSettings)
        }
        .sheet(isPresented: $showAddQuoteSheet) {
            NavigationView {
                QuoteEditView(mode: .add)
                    .environmentObject(quoteManager)
                    .environmentObject(appSettings)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // 删除箴言
    private func deleteQuotes(at offsets: IndexSet) {
        let customQuotes = quoteManager.getCustomQuotes()
        for index in offsets {
            quoteManager.deleteQuote(id: customQuotes[index].id)
        }
    }
}

// 箴言行视图
struct QuoteRow: View {
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

// 搜索栏
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// 箴言编辑模式
enum QuoteEditMode {
    case add
    case edit
}

// 箴言编辑视图
struct QuoteEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var quoteManager: QuoteManager
    @EnvironmentObject var appSettings: AppSettings
    
    var mode: QuoteEditMode
    var quote: BilingualQuote?
    
    @State private var chineseText = ""
    @State private var englishText = ""
    @State private var chineseAuthor = ""
    @State private var englishAuthor = ""
    
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
        NavigationView {
            Form {
                if isChinese {
                    Section(header: Text(NSLocalizedString("中文", comment: "Chinese section header"))) {
                        TextEditor(text: $chineseText)
                            .frame(minHeight: 60)
                            .overlay(
                                Text(chineseText.isEmpty ? NSLocalizedString("中文箴言", comment: "Chinese quote placeholder") : "")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.leading, 4)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading),
                                alignment: .topLeading
                            )
                        TextField(NSLocalizedString("中文作者", comment: "Chinese author placeholder"), text: $chineseAuthor)
                    }
                } else {
                    Section(header: Text(NSLocalizedString("英文", comment: "English section header"))) {
                        TextEditor(text: $englishText)
                            .frame(minHeight: 60)
                            .overlay(
                                Text(englishText.isEmpty ? NSLocalizedString("英文箴言", comment: "English quote placeholder") : "")
                                    .foregroundColor(Color(.placeholderText))
                                    .padding(.leading, 4)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading),
                                alignment: .topLeading
                            )
                        TextField(NSLocalizedString("英文作者", comment: "English author placeholder"), text: $englishAuthor)
                    }
                }
            }
            .navigationTitle(mode == .add 
                            ? NSLocalizedString("添加箴言", comment: "Add quote title") 
                            : NSLocalizedString("编辑箴言", comment: "Edit quote title"))
            .navigationBarItems(
                leading: Button(NSLocalizedString("取消", comment: "Cancel button")) {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(mode == .add 
                               ? NSLocalizedString("添加", comment: "Add button") 
                               : NSLocalizedString("保存", comment: "Save button")) {
                    if mode == .add {
                        quoteManager.addQuote(
                            chineseText: chineseText,
                            englishText: englishText,
                            chineseAuthor: chineseAuthor,
                            englishAuthor: englishAuthor
                        )
                    } else if let quote = quote {
                        quoteManager.updateQuote(
                            id: quote.id,
                            chineseText: chineseText,
                            englishText: englishText,
                            chineseAuthor: chineseAuthor,
                            englishAuthor: englishAuthor
                        )
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(chineseText.isEmpty || englishText.isEmpty)
            )
        }
        .onAppear {
            if let quote = quote {
                chineseText = quote.chineseText
                englishText = quote.englishText
                chineseAuthor = quote.chineseAuthor
                englishAuthor = quote.englishAuthor
            }
        }
    }
}

// 箴言详情视图
struct QuoteDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appSettings: AppSettings
    let quote: BilingualQuote
    
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
        VStack(alignment: .leading, spacing: 20) {
            Group {
                if isChinese {
                    Text(quote.chineseText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.bottom, 5)
                    
                    Text("— \(quote.chineseAuthor)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                } else {
                    Text(quote.englishText)
                        .font(.title2)
                        .fontWeight(.medium)
                        .padding(.bottom, 5)
                    
                    Text("— \(quote.englishAuthor)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 20)
        .navigationTitle(NSLocalizedString("箴言详情", comment: "Quote detail title"))
        .navigationBarItems(leading: Button(NSLocalizedString("关闭", comment: "Close button")) {
            presentationMode.wrappedValue.dismiss()
        })
    }
}

// 预览
struct QuoteListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QuoteListView()
                .environmentObject(QuoteManager.shared)
                .environmentObject(AppSettings())
        }
    }
}
