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
        ),
        BilingualQuote(
            chineseText: "专注于你能控制的，放下你无法控制的。", 
            englishText: "Focus on what you can control, let go of what you cannot.",
            chineseAuthor: "爱比克泰德", 
            englishAuthor: "Epictetus"
        ),
        BilingualQuote(
            chineseText: "今天的努力，是明天的基础。", 
            englishText: "Today's efforts are tomorrow's foundation.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "成功不是终点，失败也不是终结，勇气才是继续前进的动力。", 
            englishText: "Success is not final, failure is not fatal: it is the courage to continue that counts.",
            chineseAuthor: "温斯顿·丘吉尔", 
            englishAuthor: "Winston Churchill"
        ),
        BilingualQuote(
            chineseText: "不要追求完美，追求进步。", 
            englishText: "Don't aim for perfection, aim for progress.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "态度决定高度，习惯成就人生。", 
            englishText: "Attitude determines altitude, habits shape destiny.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "微小的积累，可以成就伟大的事业。", 
            englishText: "Small daily improvements eventually result in stunning achievements.",
            chineseAuthor: "罗宾·夏玛", 
            englishAuthor: "Robin Sharma"
        ),
        BilingualQuote(
            chineseText: "知识就是力量。", 
            englishText: "Knowledge is power.",
            chineseAuthor: "弗朗西斯·培根", 
            englishAuthor: "Francis Bacon"
        ),
        BilingualQuote(
            chineseText: "学习是一种态度，而不仅仅是一种技能。", 
            englishText: "Learning is an attitude, not just a skill.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "成长的道路上没有捷径可走，唯有脚踏实地。", 
            englishText: "There are no shortcuts to growth, only consistent steps forward.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "时间会告诉我们，简单的喜悦比复杂的悲伤更有力量。", 
            englishText: "Time will tell that simple joys are more powerful than complex sorrows.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "坚持做自己热爱的事情，成功自然会追随你。", 
            englishText: "Follow your passion, and success will follow you.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "每一个你羡慕的收获，都是努力用汗水浇灌出来的。", 
            englishText: "Every achievement you admire is the result of someone's dedication and hard work.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "勇气不是没有恐惧，而是战胜恐惧。", 
            englishText: "Courage is not the absence of fear, but the triumph over it.",
            chineseAuthor: "纳尔逊·曼德拉", 
            englishAuthor: "Nelson Mandela"
        ),
        BilingualQuote(
            chineseText: "改变，始于行动，成于坚持。", 
            englishText: "Change begins with action and is perfected through persistence.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "最好的投资就是投资自己。", 
            englishText: "The best investment you can make is in yourself.",
            chineseAuthor: "沃伦·巴菲特", 
            englishAuthor: "Warren Buffett"
        ),
        BilingualQuote(
            chineseText: "习惯决定命运，细节决定成败。", 
            englishText: "Habits determine fate, details determine success or failure.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "把每一件平凡的事做好就是不平凡。", 
            englishText: "Doing ordinary things extraordinarily well is the path to excellence.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "世上没有绝望的处境，只有对处境绝望的人。", 
            englishText: "There are no hopeless situations; there are only people who have grown hopeless about them.",
            chineseAuthor: "克莱尔·布斯", 
            englishAuthor: "Clare Boothe Luce"
        ),
        BilingualQuote(
            chineseText: "机会不会来敲门，它只会经过你的门前。", 
            englishText: "Opportunity doesn't knock, it presents itself when you beat down the door.",
            chineseAuthor: "凯尔·钱德勒", 
            englishAuthor: "Kyle Chandler"
        ),
        BilingualQuote(
            chineseText: "成功的关键在于相信自己有成功的能力。", 
            englishText: "The key to success is to believe you have the ability to succeed.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "人生就像骑自行车，要保持平衡就得不断前进。", 
            englishText: "Life is like riding a bicycle. To keep your balance, you must keep moving.",
            chineseAuthor: "爱因斯坦", 
            englishAuthor: "Albert Einstein"
        ),
        BilingualQuote(
            chineseText: "你的思想决定你的高度。", 
            englishText: "Your mind determines your altitude.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "再长的路，一步步也能走完；再短的路，不迈开双脚也无法到达。", 
            englishText: "The longest journey begins with a single step; the shortest journey cannot be completed without taking that step.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "天赋决定上限，努力决定下限。", 
            englishText: "Talent determines the ceiling, effort determines the floor.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "不要用战术上的勤奋，掩盖战略上的懒惰。", 
            englishText: "Don't use tactical diligence to mask strategic laziness.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "与其用三分钟担心，不如用三分钟思考。", 
            englishText: "Rather than spending three minutes worrying, spend three minutes thinking.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "成长的过程就是不断认识自己，接纳自己，超越自己。", 
            englishText: "Growth is the process of continuously knowing yourself, accepting yourself, and surpassing yourself.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "只要路是对的，就不怕路远。", 
            englishText: "If the path is right, don't fear the distance.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "真正的强者，不是没有眼泪的人，而是含着眼泪依然奔跑的人。", 
            englishText: "A true warrior is not one without tears, but one who continues to run despite them.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "不要等待完美的时机，要在时机中创造完美。", 
            englishText: "Don't wait for the perfect moment, create perfect moments in any situation.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "当你做对的事情，你会让一些人不高兴。不要在意，做对的事情就好。", 
            englishText: "When you do the right thing, you may make some people unhappy. Don't worry about it, just do what's right.",
            chineseAuthor: "沃伦·巴菲特", 
            englishAuthor: "Warren Buffett"
        ),
        BilingualQuote(
            chineseText: "如果你想要不同的结果，就不要做相同的事情。", 
            englishText: "If you want different results, don't do the same things.",
            chineseAuthor: "阿尔伯特·爱因斯坦", 
            englishAuthor: "Albert Einstein"
        ),
        BilingualQuote(
            chineseText: "不要担心失败，你只需要正确一次。", 
            englishText: "Don't worry about failure; you only have to be right once.",
            chineseAuthor: "德鲁·库班", 
            englishAuthor: "Drew Houston"
        ),
        BilingualQuote(
            chineseText: "人生不是一场竹龙取宝的游戏，而是一场马拉松。", 
            englishText: "Life is not a game of luck. If you want to win, work hard.",
            chineseAuthor: "苏格拉底", 
            englishAuthor: "Socrates"
        ),
        BilingualQuote(
            chineseText: "你不能改变风向，但你可以调整帆。", 
            englishText: "You can't change the direction of the wind, but you can adjust your sails.",
            chineseAuthor: "吉姆·罗恩", 
            englishAuthor: "Jim Rohn"
        ),
        BilingualQuote(
            chineseText: "每天都是新的开始，每个日出都是新的希望。", 
            englishText: "Each day is a new beginning, each sunrise brings new hope.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "最大的风险是不冒险。", 
            englishText: "The biggest risk is not taking any risk.",
            chineseAuthor: "马克·扎克伯格", 
            englishAuthor: "Mark Zuckerberg"
        ),
        BilingualQuote(
            chineseText: "不要用你的时间去追求不值得的事情。", 
            englishText: "Don't spend your time pursuing things that aren't worth it.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "成功不是偏爱某个人，而是偏爱那些有准备的人。", 
            englishText: "Success is not about favoring someone, but favoring those who are prepared.",
            chineseAuthor: "路易·巴斯德", 
            englishAuthor: "Louis Pasteur"
        ),
        BilingualQuote(
            chineseText: "你的态度，决定了你的高度。", 
            englishText: "Your attitude determines your altitude.",
            chineseAuthor: "卡罗尔·尼克尔森", 
            englishAuthor: "Carole Nickerson"
        ),
        BilingualQuote(
            chineseText: "当你改变了你看待事物的方式，你所看待的事物也会改变。", 
            englishText: "When you change the way you look at things, the things you look at change.",
            chineseAuthor: "韦恩·戴尔", 
            englishAuthor: "Wayne Dyer"
        ),
        BilingualQuote(
            chineseText: "不要让昨天的阴影遮住了今天的阳光。", 
            englishText: "Don't let yesterday's shadows block today's sunshine.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "当你做的事情有意义，你就会找到做事情的动力。", 
            englishText: "When what you do matters, you find the motivation to do it.",
            chineseAuthor: "佚名", 
            englishAuthor: "Anonymous"
        ),
        BilingualQuote(
            chineseText: "不要等待机会，要创造机会。", 
            englishText: "Don't wait for opportunity. Create it.",
            chineseAuthor: "乔治·伯纳德·肖", 
            englishAuthor: "George Bernard Shaw"
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
