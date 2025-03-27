import SwiftUI

// MARK: - 设置项容器

struct SettingsSectionHeader: View {
    var title: String
    var systemImage: String
    var tintColor: Color = .blue
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(tintColor)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 26, height: 26)
                .background(tintColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            
            Text(title)
                .font(.headline)
        }
    }
}

// MARK: - 颜色选择器

struct ColorPickerRow: View {
    @Binding var selectedColor: AppAccentColor
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(AppAccentColor.allCases, id: \.self) { color in
                ZStack {
                    Circle()
                        .fill(color.color)
                        .frame(width: 48, height: 48)
                        .shadow(color: color.color.opacity(0.5), radius: 3, x: 0, y: 2)
                    
                    if selectedColor == color {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedColor = color
                    }
                }
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - 主题选择器

struct ThemePickerRow: View {
    @Binding var selectedTheme: AppTheme
    var accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                ThemeOption(
                    theme: theme,
                    isSelected: selectedTheme == theme,
                    accentColor: accentColor
                )
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedTheme = theme
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ThemeOption: View {
    var theme: AppTheme
    var isSelected: Bool
    var accentColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 84, height: 50)
                    .foregroundColor(backgroundColor)
                
                Image(systemName: theme.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
            
            Text(theme.displayName)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
    
    var backgroundColor: Color {
        switch theme {
        case .system:
            return Color(.systemGray5)
        case .light:
            return .white
        case .dark:
            return Color(.systemGray6)
        }
    }
    
    var iconColor: Color {
        switch theme {
        case .system:
            return accentColor
        case .light:
            return .orange
        case .dark:
            return .purple
        }
    }
}

// MARK: - 滑块设置行

struct SliderSettingRow: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var unit: String
    var accentColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .foregroundColor(.secondary)
            }
            
            Slider(value: $value, in: range, step: step)
                .accentColor(accentColor)
        }
    }
}

// MARK: - 选项选择行

struct PickerSettingRow<T: CaseIterable & Identifiable & RawRepresentable>: View where T.RawValue == String {
    var title: String
    @Binding var selection: T
    var options: [T]
    var getDisplayName: (T) -> String
    
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(getDisplayName(option)).tag(option)
            }
        }
    }
}

// MARK: - 开关设置行

struct ToggleSettingRow: View {
    var title: String
    var description: String?
    @Binding var isOn: Bool
    var accentColor: Color = .blue
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: accentColor))
        }
    }
}

// MARK: - 数字调节设置行

struct StepperSettingRow: View {
    var title: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    var unit: String
    var accentColor: Color = .blue
    
    var body: some View {
        HStack {
            Text(title)
            
            Spacer()
            
            Text("\(value) \(unit)")
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }
}

// MARK: - 设置操作按钮

struct SettingsActionButton: View {
    var title: String
    var systemImage: String
    var color: Color
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
} 