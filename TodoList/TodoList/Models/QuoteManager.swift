import Foundation

// 名言管理器
class QuoteManager {
    static let shared = QuoteManager()
    
    // 双语名言集合
    private let quotes: [BilingualQuote] = [
        BilingualQuote(
            chineseText: "生活不是等待风暴过去，而是学会在雨中跳舞。", 
            englishText: "Life isn't about waiting for the storm to pass, it's about learning to dance in the rain.",
            chineseAuthor: "薇薇安·格林", 
            englishAuthor: "Vivian Greene"
        ),
        BilingualQuote(
            chineseText: "人生最大的荣耀不在于永不跌倒，而在于每次跌倒后都能爬起来。", 
            englishText: "The greatest glory in living lies not in never falling, but in rising every time we fall.",
            chineseAuthor: "纳尔逊·曼德拉", 
            englishAuthor: "Nelson Mandela"
        ),
        BilingualQuote(
            chineseText: "不要为成功而努力，要为做一个有价值的人而努力。", 
            englishText: "Try not to become a person of success, but rather try to become a person of value.",
            chineseAuthor: "爱因斯坦", 
            englishAuthor: "Albert Einstein"
        ),
        BilingualQuote(
            chineseText: "你的时间有限，所以不要为别人而活。不要被教条所限，不要活在别人的观念里。", 
            englishText: "Your time is limited, so don't waste it living someone else's life. Don't be trapped by dogma – which is living with the results of other people's thinking.",
            chineseAuthor: "史蒂夫·乔布斯", 
            englishAuthor: "Steve Jobs"
        ),
        BilingualQuote(
            chineseText: "最困难的时刻，也是离成功不远的时候。", 
            englishText: "When everything seems to be going against you, remember that the airplane takes off against the wind, not with it.",
            chineseAuthor: "拿破仑·希尔", 
            englishAuthor: "Napoleon Hill"
        ),
        BilingualQuote(
            chineseText: "伟大的事业不是靠力气速度和身体的敏捷完成的，而是靠性格意志和知识的力量完成的。", 
            englishText: "Great works are performed not by strength but by perseverance.",
            chineseAuthor: "塞缪尔·约翰逊", 
            englishAuthor: "Samuel Johnson"
        ),
        BilingualQuote(
            chineseText: "成功的秘诀在于坚持自己的目标并不断努力。", 
            englishText: "The secret of success is constancy to purpose.",
            chineseAuthor: "本杰明·迪斯雷利", 
            englishAuthor: "Benjamin Disraeli"
        ),
        BilingualQuote(
            chineseText: "我们必须接受失望，因为它是有限的，但千万不可失去希望，因为它是无穷的。", 
            englishText: "We must accept finite disappointment, but never lose infinite hope.",
            chineseAuthor: "马丁·路德·金", 
            englishAuthor: "Martin Luther King Jr."
        ),
        BilingualQuote(
            chineseText: "世界上最快乐的事，莫过于为理想而奋斗。", 
            englishText: "The happiest of all lives is a busy solitude.",
            chineseAuthor: "苏格拉底", 
            englishAuthor: "Socrates"
        ),
        BilingualQuote(
            chineseText: "人的一生可能燃烧也可能腐朽，我不能腐朽，我愿意燃烧起来。", 
            englishText: "A man's life may stagnate or it may burn; I cannot let mine stagnate, I choose to burn.",
            chineseAuthor: "奥斯特洛夫斯基", 
            englishAuthor: "Nikolai Ostrovsky"
        ),
        BilingualQuote(
            chineseText: "每天告诉自己一次：我真的很不错。", 
            englishText: "Every day, tell yourself: I am really quite good.",
            chineseAuthor: "戴尔·卡耐基", 
            englishAuthor: "Dale Carnegie"
        ),
        BilingualQuote(
            chineseText: "生命不在于活得长与短，而在于顿悟的早与晚。", 
            englishText: "Life is not measured by its length, but by its depth of understanding.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "目标的坚定是性格中最必要的力量源泉之一，也是成功的利器之一。", 
            englishText: "Definiteness of purpose is the starting point of all achievement.",
            chineseAuthor: "拿破仑·希尔", 
            englishAuthor: "Napoleon Hill"
        ),
        BilingualQuote(
            chineseText: "今天做的最好，明天才会更好。", 
            englishText: "Do the best you can today, and tomorrow will be better.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "行动是治愈恐惧的良药，而犹豫拖延将不断滋养恐惧。", 
            englishText: "Action is a great restorer and builder of confidence. Inaction is not only the result, but the cause, of fear.",
            chineseAuthor: "威廉·詹姆斯", 
            englishAuthor: "William James"
        ),
        BilingualQuote(
            chineseText: "一个人的价值，应该看他贡献什么，而不是取得什么。", 
            englishText: "The value of a man should be seen in what he gives and not in what he is able to receive.",
            chineseAuthor: "爱因斯坦", 
            englishAuthor: "Albert Einstein"
        ),
        BilingualQuote(
            chineseText: "不要等待机会，而要创造机会。", 
            englishText: "Don't wait for opportunity, create it.",
            chineseAuthor: "林肯", 
            englishAuthor: "Abraham Lincoln"
        ),
        BilingualQuote(
            chineseText: "没有天生的信心，只有不断培养的信心。", 
            englishText: "Confidence is not something you're born with, but something you must constantly develop.",
            chineseAuthor: "布莱恩·特雷西", 
            englishAuthor: "Brian Tracy"
        ),
        BilingualQuote(
            chineseText: "人生如同故事。重要的并不在有多长，而是在有多好。", 
            englishText: "Life is like a story. It's not about how long it is, but how good it is.",
            chineseAuthor: "塞内卡", 
            englishAuthor: "Seneca"
        ),
        BilingualQuote(
            chineseText: "忘掉失败，不过要牢记失败中的教训。", 
            englishText: "Forget the failures. Keep the lessons.",
            chineseAuthor: "比尔·盖茨", 
            englishAuthor: "Bill Gates"
        )
    ]
    
    // 获取随机名言
    func getRandomQuote() -> Quote {
        let bilingualQuote = quotes.randomElement() ?? BilingualQuote(
            chineseText: "每一天都是新的开始", 
            englishText: "Every day is a new beginning",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        )
        
        // 根据当前系统语言返回相应的Quote对象
        let preferredLanguages = Locale.preferredLanguages
        let isChinesePreferred = preferredLanguages.first?.contains("zh") ?? false
        
        if isChinesePreferred {
            return Quote(text: bilingualQuote.chineseText, author: bilingualQuote.chineseAuthor)
        } else {
            return Quote(text: bilingualQuote.englishText, author: bilingualQuote.englishAuthor)
        }
    }
}

// 双语名言模型
struct BilingualQuote {
    let chineseText: String
    let englishText: String
    let chineseAuthor: String
    let englishAuthor: String
}

// 名言模型
struct Quote {
    let text: String
    let author: String
    
    // 本地化的文本
    var localizedText: String {
        return NSLocalizedString(text, comment: "Quote text")
    }
    
    // 本地化的作者
    var localizedAuthor: String {
        return NSLocalizedString(author, comment: "Quote author")
    }
}
