//
//  NotificationViewController.swift
//  reminder
//
//  Created by donaldsong(宋黎明) on 2018-2-8.
//  Copyright © 2018 donaldsong(宋黎明). All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import MobileCoreServices

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet var label: UILabel?
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var containerView: UIView!


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
        view.backgroundColor = .white
        print(self)
    }
    
    func didReceive(_ notification: UNNotification) {
        let c = notification.request.content
        label?.text = c.body
        // if UTTypeConformsTo(kUTTypeJPEG as CFString, kUTTypeImage as CFString) {
        //   print(true)
        // }
        for a in c.attachments {
            print(a)
            if a.url.startAccessingSecurityScopedResource() {
                let data = try! Data.init(contentsOf: a.url)
                switch a.identifier {
                case "Audio":
                    fallthrough

                case "Video":
                    imageView.removeFromSuperview()

                case "Image":
                    // 若不用 async，就显示不出来。
                    // Debug 时此处打断点，能显示图片
                    DispatchQueue.main.async {
                        let i = UIImage(data: data)
                        self.imageView.image = i
                        //imageView.setNeedsDisplay()
                    }

                default:
                    break
                }
                a.url.stopAccessingSecurityScopedResource()
            }
        }
    }

    func didReceive(_ response: UNNotificationResponse, completionHandler completion: @escaping (UNNotificationContentExtensionResponseOption) -> Void) {
        print(response)
        completion(.dismissAndForwardAction)
    }
}
