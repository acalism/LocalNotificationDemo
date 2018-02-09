//
//  NotificationManager.swift
//  LocalNotificationDemo
//
//  Created by donaldsong(宋黎明) on 2018-2-5.
//  Copyright © 2018 donaldsong(宋黎明). All rights reserved.
//

import UIKit
import UserNotifications


let imagePath = Bundle.main.url(forResource: "watch", withExtension: "png")!
let image = try! UNNotificationAttachment(identifier: "Image", url: imagePath, options: nil)
let audioPath = Bundle.main.url(forResource: "T-ara (티아라)-뷰티풀 걸 (Beautiful Girl)", withExtension: "mp3")!
let audio = try! UNNotificationAttachment(identifier: "Audio", url: audioPath, options: nil)
let videoPath = Bundle.main.url(forResource: "superquest", withExtension: "mp4")!
let video = try! UNNotificationAttachment(identifier: "Video", url: videoPath, options: nil)

let sound = UNNotificationSound(named: "submarine.caf")

class NotificationManager: NSObject {

    static let shared = NotificationManager()
    private override init() { super.init() }

    enum CategoryIdentifier: String {
        case reminder // = "UYLReminderCategory"
    }

    enum ActionIdentifier: String {
//        case dimiss     = UNNotificationDismissActionIdentifier = "com.apple.UNNotificationDismissActionIdentifier"
//        case `default`  = UNNotificationDefaultActionIdentifier = "com.apple.UNNotificationDefaultActionIdentifier"
        case snooze = "com.qq.bikan.UNNotificationSnoozeActionIdentifier"
        case stop   = "com.qq.bikan.UNNotificationStopActionIdentifier"
        case delete = "com.qq.bikan.UNNotificationDeleteActionIdentifier"
    }

    enum NotificationId: String {
        case location
        case timer
        case date
    }

    /// 向操作系统索要推送权限（并获取推送 token）
    static func registerRemoteNotifications() {
        // 1. 注册获取 deviceToken 的系统通知（用户打开推送时就会有回调————关闭再打开，也会再次回调，直到unregister）
        //UIApplication.shared.registerForRemoteNotifications()

        // 2. 自定义通知响应事件
        let snoozeAction = UNNotificationAction(identifier: ActionIdentifier.snooze.rawValue, title: "Snooze", options: [])
        let stopAction   = UNNotificationAction(identifier: ActionIdentifier.stop.rawValue, title: "Stop", options: [.destructive])
        //let deleteAction   = UNNotificationAction(identifier: ActionIdentifier.delete.rawValue, title: "Delete", options: [.destructive])
        let category     = UNNotificationCategory(identifier: CategoryIdentifier.reminder.rawValue, actions: [snoozeAction, stopAction], intentIdentifiers: [], options: .customDismissAction)


        // 3. 获取用户授权
        let uc = UNUserNotificationCenter.current()
        uc.setNotificationCategories([category])
        uc.delegate = shared
        uc.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if let e = error { // 无论是拒绝推送，还是不提供 aps-certificate，此 error 始终为 nil
                print("UNUserNotificationCenter 注册通知失败, \(e)")
            }
            DispatchQueue.main.async {
                onAuthorization(granted: granted)
            }
        }

        // 4. 验证授权结果（非必须）
        uc.getNotificationSettings { (settings) in
            guard settings.authorizationStatus == .authorized else {
                print(settings.authorizationStatus)
                return
            }
        }
    }


    static func onAuthorization(granted: Bool) {
        guard granted else {
            return
        }
        //
    }


    /// 得到了推送token
    static func onReceiveDeviceToken(_ deviceToken: Data) {
        print(deviceToken)
    }


    /// 由于网络原因没取得token，另外模拟器也得不到 token，未配置 aps-certificate 的项目也得不到 token
    static func onFailedToReceiveDeviceToken(error: Error) {
        print("failed to register")
    }
}



@available(iOS 10.0, *)
extension NotificationManager: UNUserNotificationCenterDelegate {

    // 用户点击推送消息（可能包含自定义的 action）
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let t = response.notification.request.trigger {
            switch t {
            case is UNPushNotificationTrigger:
                NotificationManager.onReceiveRemoteNotification(userInfo: response.notification.request.content.userInfo)

            default:
                break
            }
        }

        defer {
            completionHandler()
        }

        guard let categoryId = NotificationManager.CategoryIdentifier(rawValue: response.notification.request.content.categoryIdentifier) else {
            return
        }

        switch categoryId {
        case .reminder:
            switch response.actionIdentifier {
            case UNNotificationDismissActionIdentifier: // 不作任何操作，且该 category 有 .customDismissAction 时
                print("Dismiss Action: \(response.actionIdentifier)")

            case UNNotificationDefaultActionIdentifier: // 点内容
                print("Default: \(response.actionIdentifier)")

            default:
                guard let id = NotificationManager.ActionIdentifier(rawValue: response.actionIdentifier) else {
                    print("Unknown action")
                    break
                }

                switch id {
                case .snooze:
                    print("Snooze")

                case .stop:
                    print("Stop")
                    fallthrough

                case .delete:
                    center.removeDeliveredNotifications(withIdentifiers: [response.notification.request.identifier])
                }
            }
        }
    }

    // app在前台收到推送消息。如果这儿的completionHandler参数包含alert，用户点击alert将会调用第一个委托方法
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let t = notification.request.trigger {
            switch t {
            case is UNPushNotificationTrigger:
                NotificationManager.onReceiveRemoteNotification(userInfo: notification.request.content.userInfo)
                completionHandler([])
                return

            default:
                break
            }
        }
        completionHandler([.alert, .sound])
    }
}

// MARK: - 推送消息处理（冷启动和热启动）

extension NotificationManager {

    /// 从推送消息冷启动app（等首页完全加载后再处理）
    ///
    /// - Parameter launchOptions: 启动时包含的信息（可能包含推送信息）
    static func onLaunch(with launchOptions: [UIApplicationLaunchOptionsKey : Any]?) {

        // TODO: 事先清理
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        guard let op = launchOptions, let userInfo = op[.remoteNotification] as? [AnyHashable : Any] else {
            return
        }
        // 启动时 UIApplication.shared.applicationState == .inactive
        NotificationManager.handle(receivedRemoteMessage: userInfo)
    }




    /// 从推送消息热启动 app
    ///
    /// - Parameter userInfo: 推送消息字典
    static func onReceiveRemoteNotification(userInfo: [AnyHashable : Any]) {
        // 处理推送消息跳转逻辑
        NotificationManager.handle(receivedRemoteMessage: userInfo, appState: UIApplication.shared.applicationState)
    }

    static func handle(receivedRemoteMessage message: [AnyHashable : Any], appState: UIApplicationState = .inactive) {
        //
    }
}

