import SwiftUI

// 箴言列表管理界面
struct QuoteListView: View {
    @EnvironmentObject var quoteManager: QuoteManager
    @State private var showAddQuoteSheet = false
    @State private var showEditQuoteSheet = false
    @State private var selectedQuote: BilingualQuote?
    @State private var showingDefaultQuotes = false
    @State private var searchText = ""
    
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
                            .onTapGesture {
                                if !showingDefaultQuotes {
                                    selectedQuote = quote
                                    showEditQuoteSheet = true
                                }
                            }
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
        }
        .sheet(isPresented: $showEditQuoteSheet, onDismiss: {
            selectedQuote = nil
        }) {
            if let quote = selectedQuote {
                QuoteEditView(mode: .edit, quote: quote)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.chineseText)
                .font(.headline)
                .lineLimit(2)
            
            Text("— \(quote.chineseAuthor)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text(quote.englishText)
                .font(.headline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text("— \(quote.englishAuthor)")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
    
    var mode: QuoteEditMode
    var quote: BilingualQuote?
    
    @State private var chineseText = ""
    @State private var englishText = ""
    @State private var chineseAuthor = ""
    @State private var englishAuthor = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(NSLocalizedString("中文", comment: "Chinese section header"))) {
                    TextField(NSLocalizedString("中文箴言", comment: "Chinese quote placeholder"), text: $chineseText)
                    TextField(NSLocalizedString("中文作者", comment: "Chinese author placeholder"), text: $chineseAuthor)
                }
                
                Section(header: Text(NSLocalizedString("英文", comment: "English section header"))) {
                    TextField(NSLocalizedString("英文箴言", comment: "English quote placeholder"), text: $englishText)
                    TextField(NSLocalizedString("英文作者", comment: "English author placeholder"), text: $englishAuthor)
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

// 预览
struct QuoteListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QuoteListView()
                .environmentObject(QuoteManager.shared)
        }
    }
}
