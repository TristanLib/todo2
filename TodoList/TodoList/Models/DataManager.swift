import Foundation
import SwiftUI

class DataManager {
    static let shared = DataManager()
    
    // 文件操作的文档目录
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 获取备份文件的URL
    private func getBackupFileURL(withName fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    // 创建备份文件
    func createBackup(tasks: [Task], completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(tasks)
            
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: " ", with: "_")
            
            let fileName = "TodoBackup_\(timestamp).json"
            let fileURL = getBackupFileURL(withName: fileName)
            
            try data.write(to: fileURL)
            completion(.success(fileURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 从文件恢复备份
    func restoreFromFile(at url: URL, completion: @escaping (Result<[Task], Error>) -> Void) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let tasks = try decoder.decode([Task].self, from: data)
            completion(.success(tasks))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 获取所有备份文件列表
    func getBackupFiles() -> [URL] {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return fileURLs.filter { $0.lastPathComponent.starts(with: "TodoBackup_") }
        } catch {
            print("Error getting backup files: \(error)")
            return []
        }
    }
    
    // 删除备份文件
    func deleteBackupFile(at url: URL) -> Bool {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
            return true
        } catch {
            print("Error deleting backup file: \(error)")
            return false
        }
    }
    
    // 分享备份文件
    func shareBackupFile(at url: URL) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        return activityVC
    }
} 