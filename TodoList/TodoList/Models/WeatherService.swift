import Foundation
import Combine
import CoreLocation

// 天气数据模型
struct WeatherData: Codable {
    let location: String
    let temperature: Double
    let condition: String
    let iconCode: String
    
    // 获取对应的系统图标名称
    var systemIconName: String {
        switch iconCode {
        case "01d": return "sun.max.fill" // 晴天（白天）
        case "01n": return "moon.stars.fill" // 晴天（夜间）
        case "02d", "03d", "04d": return "cloud.sun.fill" // 多云（白天）
        case "02n", "03n", "04n": return "cloud.moon.fill" // 多云（夜间）
        case "09d", "09n": return "cloud.drizzle.fill" // 小雨
        case "10d": return "cloud.sun.rain.fill" // 雨（白天）
        case "10n": return "cloud.moon.rain.fill" // 雨（夜间）
        case "11d", "11n": return "cloud.bolt.rain.fill" // 雷雨
        case "13d", "13n": return "cloud.snow.fill" // 雪
        case "50d", "50n": return "cloud.fog.fill" // 雾
        default: return "sun.max.fill" // 默认图标
        }
    }
}

class WeatherService: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // 单例模式
    static let shared = WeatherService()
    
    private init() {
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // 获取当前位置的天气
    func fetchCurrentWeather() {
        isLoading = true
        errorMessage = nil
        
        // 模拟天气数据获取 (实际应用中应该调用真实的天气API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 模拟数据
            self.currentWeather = WeatherData(
                location: "北京",
                temperature: 22.5,
                condition: "晴朗",
                iconCode: "01d"
            )
            self.isLoading = false
        }
    }
    
    // 获取指定城市的天气
    func fetchWeather(for city: String) {
        isLoading = true
        errorMessage = nil
        
        // 模拟天气数据获取 (实际应用中应该调用真实的天气API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 模拟数据
            self.currentWeather = WeatherData(
                location: city,
                temperature: 22.5,
                condition: "晴朗",
                iconCode: "01d"
            )
            self.isLoading = false
        }
    }
}
