import SwiftUI

// MARK: - 动画按钮

struct AnimatedButton: View {
    var title: String
    var systemImage: String?
    var color: Color
    var action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(AnimationUtils.gentlePop) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AnimationUtils.gentlePop) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(isPressed ? 0.95 : 1)
        }
    }
}

// MARK: - 动画复选框

struct AnimatedCheckbox: View {
    var isChecked: Bool
    var color: Color = .blue
    var action: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            withAnimation(AnimationUtils.quickBounce) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                action()
                
                withAnimation(AnimationUtils.quickBounce) {
                    isAnimating = false
                }
            }
        }) {
            ZStack {
                Circle()
                    .strokeBorder(isChecked ? color : Color.gray, lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .scaleEffect(isAnimating ? 1.1 : 1)
                
                if isChecked {
                    Circle()
                        .fill(color)
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 动画加载指示器

struct AnimatedLoader: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(Color.blue, lineWidth: 4)
            .frame(width: 40, height: 40)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - 任务项的动画行

struct AnimatedTaskRow: View {
    var task: Task
    var toggleAction: () -> Void
    @State private var isPresented = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AnimatedCheckbox(isChecked: task.isCompleted, action: toggleAction)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 10) {
                    if let category = task.category {
                        Text(category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            
                            Text(dateFormatter.string(from: dueDate))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .opacity(isPresented ? 1 : 0)
        .offset(y: isPresented ? 0 : 20)
        .onAppear {
            withAnimation(AnimationUtils.spring.delay(0.1)) {
                isPresented = true
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - 动画进度条

struct AnimatedProgressBar: View {
    var value: Double
    var color: Color = .blue
    @State private var animatedValue: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color(.systemGray5))
                    .cornerRadius(5)
                
                Rectangle()
                    .frame(width: min(CGFloat(animatedValue) * geometry.size.width, geometry.size.width))
                    .foregroundColor(color)
                    .cornerRadius(5)
            }
        }
        .onAppear {
            withAnimation(AnimationUtils.spring.delay(0.2)) {
                animatedValue = value
            }
        }
        .onChange(of: value) { newValue in
            withAnimation(AnimationUtils.spring) {
                animatedValue = newValue
            }
        }
    }
}

// MARK: - 分类选择芯片组

struct AnimatedCategoryChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : (isHovered ? Color(.systemGray5) : Color(.systemGray6)))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .scaleEffect(isHovered ? 1.05 : 1)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(AnimationUtils.snappy) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 滑入视图修饰器

struct SlideInGroupModifier: ViewModifier {
    var isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .offset(y: isPresented ? 0 : 50)
            .animation(
                Animation.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0),
                value: isPresented
            )
    }
}

extension View {
    func slideInGroup(isPresented: Bool) -> some View {
        self.modifier(SlideInGroupModifier(isPresented: isPresented))
    }
} 