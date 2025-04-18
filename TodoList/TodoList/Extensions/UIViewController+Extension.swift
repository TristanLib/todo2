import UIKit

// UIViewController 扩展，添加查找导航控制器的方法
// Extension for UIViewController, adding a method to find navigation controller
extension UIViewController {
    
    /// 查找当前视图控制器的导航控制器
    /// Find the navigation controller for the current view controller
    func findNavigationController() -> UINavigationController? {
        // 如果自身就是导航控制器，直接返回
        // If self is a navigation controller, return directly
        if let nav = self as? UINavigationController {
            return nav
        }
        
        // 如果有父导航控制器，返回父导航控制器
        // If there is a parent navigation controller, return it
        if let nav = self.navigationController {
            return nav
        }
        
        // 递归查找父视图控制器
        // Recursively find parent view controller
        if let parent = self.parent {
            return parent.findNavigationController()
        }
        
        // 查找呈现该视图控制器的导航控制器
        // Find the navigation controller that presented this view controller
        if let presenting = self.presentingViewController {
            return presenting.findNavigationController()
        }
        
        return nil
    }
}
