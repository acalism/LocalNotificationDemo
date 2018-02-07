//
//  MoreNotificationViewController.swift
//  LocalNotificationDemo
//
//  Created by donaldsong(宋黎明) on 2018-2-5.
//  Copyright © 2018 donaldsong(宋黎明). All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation

class MoreNotificationViewController: UITableViewController {


    override func viewDidLoad() {
        super.viewDidLoad()

        // clearsSelectionOnViewWillAppear = true
        // navigationItem.rightBarButtonItem = editButtonItem

        tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()



    }

    // MARK: - Table view data source

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! Cell
        cell.bindData(dataArray[indexPath.row])
        return cell
    }

    override func tableView(_ tv: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(Cell.onSwitch(_:)) {
            //
        }
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */


    var dataArray = [
        //Model(eventName: "声音", isOn: true, attach: Model.Attach.time(Date().addingTimeInterval(10), Cell.timeFormatter)),
        Model(eventName: "日期", isOn: true, attach: Model.Attach.time(Date(), Cell.dateFormatter)),
        Model(eventName: "地理位置", isOn: true, attach: Model.Attach.location(CLLocation(latitude: 23, longitude: 114)))
    ]

    struct Model {
        let eventName: String
        var isOn: Bool
        var attach: Attach

        enum Attach {
            case time(Date, DateFormatter)
            case location(CLLocation)
        }
    }


    class Cell: UITableViewCell {

        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter
        }()

        static let timeFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return formatter
        }()

        let leftLabel = UILabel()
        let middleLabel = UILabel()
        let `switch` = UISwitch()

        override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            loadContentView()
        }

        required init?(coder aDecoder: NSCoder) {
            //fatalError("init(coder:) has not been implemented")
            super.init(coder: aDecoder)
            loadContentView()
        }

        func loadContentView() {
            contentView.addSubview(leftLabel)
            contentView.addSubview(middleLabel)
            contentView.addSubview(`switch`)
            `switch`.isOn = false

            `switch`.addTarget(self, action: #selector(onSwitch(_:)), for: .valueChanged)
        }

        var model: Model!
        func bindData(_ model: Model) {
            self.model = model

            leftLabel.text = model.eventName
            `switch`.isOn = model.isOn

            let center = UNUserNotificationCenter.current()
//            let stopAction = UNNotificationAction(identifier: NotificationManager.ActionIdentifier.stop.rawValue, title: "Stop", options: [])
//            let snoozeAction = UNNotificationAction(identifier: NotificationManager.ActionIdentifier.snooze.rawValue, title: "Snooze", options: [])
//            let category = UNNotificationCategory(identifier: NotificationManager.CategoryIdentifier.reminder.rawValue, actions: [snoozeAction, stopAction], intentIdentifiers: [], options: [])

            switch model.attach {
            case .time(let date, let formatter):
                middleLabel.text = formatter.string(from: date)
                setNeedsLayout()

                let moviePath = Bundle.main.url(forResource: "watch", withExtension: "png")!
                let att = try! UNNotificationAttachment(identifier: NotificationManager.ActionIdentifier.stop.rawValue, url: moviePath, options: nil)

                let content = UNMutableNotificationContent()
                content.title = NSString.localizedUserNotificationString(forKey: "Wake up!", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "Rise and shine! It's morning time!", arguments: nil)
                content.attachments = [att]
                content.sound = UNNotificationSound(named: "submarine.caf")
                content.categoryIdentifier = NotificationManager.CategoryIdentifier.reminder.rawValue

                // Configure the trigger for a 7am wakeup.
                var dateInfo = DateComponents()
                dateInfo.hour = 7
                dateInfo.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)

                // Create the request object.
                let request = UNNotificationRequest(identifier: "MorningAlarm", content: content, trigger: trigger)
                center.add(request, withCompletionHandler: { (error) in
                    if let e = error {
                        print(e)
                    }
                })

            case .location(let locate):
                locationManager.requestAlwaysAuthorization()
                CLGeocoder().reverseGeocodeLocation(locate, completionHandler: { (marks, error) in
                    guard error == nil, let mark = marks?.first else {
                        self.setNeedsLayout()
                        return
                    }
                    self.middleLabel.text = [mark.name, mark.locality].flatMap{$0}.joined(separator: ", ")
                    self.setNeedsLayout()
                })
            }
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            leftLabel.sizeToFit()
            middleLabel.sizeToFit()
            `switch`.sizeToFit()
            leftLabel.frame.origin = CGPoint(x: 15, y: (contentView.frame.height - leftLabel.frame.height) * 0.5)
            middleLabel.frame.origin = CGPoint(x: (contentView.frame.width - middleLabel.frame.width) * 0.5, y: (contentView.frame.height - middleLabel.frame.height) * 0.5)
            `switch`.center = CGPoint(x: contentView.frame.width - 15 - `switch`.frame.width * 0.5, y: contentView.frame.height * 0.5)
        }

        @objc
        func onSwitch(_ sender: Any) {
            forward(for: #selector(onSwitch(_:)))
        }
    }

}


let locationManager = CLLocationManager()



// MARK: - FindHostView

protocol FindHostView {
    associatedtype T
    var hostView: T? { get }
}

extension FindHostView where Self: UIView {
    var hostView: T? {
        var sv = superview
        while nil != sv {
            if let s = sv as? T  {
                return s
            }
            sv = sv?.superview
        }
        return nil
    }
}

// UICollectionViewCell 和 header/footer 都是ReusableView类型
extension UICollectionReusableView: FindHostView {
    typealias T = UICollectionView
}
extension UITableViewCell: FindHostView {
    typealias T = UITableView
}
extension UITableViewHeaderFooterView: FindHostView {
    typealias T = UITableView
}

// MARK: - Forward PerformAction to its delegate

extension FindHostView where Self: UITableViewCell {
    func forward(for aSelector: Selector) {
        if let cv = hostView, let ip = cv.indexPath(for: self) {
            cv.delegate?.tableView?(cv, performAction: aSelector, forRowAt: ip, withSender: self)
        }
    }
}
