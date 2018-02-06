//
//  AppDelegate+UserNotification.swift
//  LocalNotificationDemo
//
//  Created by donaldsong(宋黎明) on 2018-2-5.
//  Copyright © 2018 donaldsong(宋黎明). All rights reserved.
//

import UIKit
import UserNotifications


extension AppDelegate {
    func application(_ app: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.onReceiveDeviceToken(deviceToken)
    }

    // 模拟器得不到 token，没配置 aps-certificate 的项目也得不到 token，网络原因也可能导致得不到 token
    func application(_ app: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationManager.onFailedToReceiveDeviceToken(error: error)
    }
}

/*
@available(iOS 8.0, *)
extension AppDelegate {
    // 在 app.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)) 之后收到用户“接受”或“拒绝”及“默拒”后，此委托方法被调用
    func application(_ app: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {

        // 已申请推送权限，所作的检测才有效

        // 1. 征询“推送许可”时，用户把app切到后台————默拒了推送
        // 2. 在系统设置里打开推送，但关掉所有形式的提醒，等价于拒绝推送（得不到token，也收不到推送）
        // 3. 关掉 badge, alert 和 sound 时，notificationSettings.types.rawValue == 0 && app.isRegisteredForRemoteNotifications 成立，但能得到token，也能收到推送（锁屏和通知中心也能看到推送）————说明types涵盖并不全面
        // 对于模拟器来说，由于不能接收推送，所以 isRegisteredForRemoteNotifications 始终为 false

        NotificationManager.onAuthorization(granted: app.isRegisteredForRemoteNotifications)
    }


    // 点击推送 alert 拉起 app 时，
    // 或者 app 在前台时收到推送时
    func application(_ app: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        NotificationManager.onReceiveRemoteNotification(userInfo: userInfo)
    }

    // 自定义的 action
    func application(_ app: UIApplication, handleActionWithIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any], completionHandler: @escaping () -> Swift.Void) {
        completionHandler()
    }
}
 */



@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {

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
                    print("Delete")
                }
            }
        }

        completionHandler()
    }

    // app在前台收到推送消息。如果这儿的completionHandler参数包含alert，用户点击alert将会调用第一个委托方法
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let t = notification.request.trigger, t is UNPushNotificationTrigger {
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
