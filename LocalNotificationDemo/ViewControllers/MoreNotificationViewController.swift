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


let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.dateStyle = .none
    formatter.timeStyle = .medium
    return formatter
}()

private let noticeIds = ["MorningAlarm", "GetOffAlarm"]

class MoreNotificationViewController: UITableViewController {


    override func viewDidLoad() {
        super.viewDidLoad()

        // clearsSelectionOnViewWillAppear = true
        // navigationItem.rightBarButtonItem = editButtonItem

        tableView.register(Cell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
    }

    deinit {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: noticeIds)
    }

    // MARK: - Table view data source

    override func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataArray.count
    }

    override func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! Cell
        cell.bindData(dataArray[indexPath.row])
        return cell
    }

    override func tableView(_ tv: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(Cell.onSwitch(_:)), let s = sender as? Cell {
            dataArray[indexPath.row].isOn = s.`switch`.isOn
            if s.`switch`.isOn {
                s.bindData(dataArray[indexPath.row])
            } else  {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [noticeIds[1]])
            }
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
        Model(eventName: "日期", isOn: true, attach: Model.Attach.time(Date(), dateFormatter)),
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

            createLocalNotification(model: model, completion: { [weak self] in
                self?.setNeedsLayout()
            })
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

        func createLocalNotification(model: Model, completion: @escaping()->Void) {
            let center = UNUserNotificationCenter.current()

            let content = UNMutableNotificationContent()
            content.attachments = [video]
            content.sound = sound
            content.categoryIdentifier = NotificationManager.CategoryIdentifier.reminder.rawValue

            switch model.attach {
            case .time(let date, let formatter):
                middleLabel.text = formatter.string(from: date)
                completion()

                content.title = NSString.localizedUserNotificationString(forKey: "Wake up!", arguments: nil)
                content.subtitle = NSString.localizedUserNotificationString(forKey: "Rise and shine!", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "It's morning time!", arguments: nil)

                // Configure the trigger for a 7am wakeup.
                let dateInfo = Calendar.current.dateComponents([.hour, .minute, .second], from: Date().addingTimeInterval(5))
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateInfo, repeats: false)

                // Create the request object.
                let request = UNNotificationRequest(identifier: noticeIds[0], content: content, trigger: trigger)
                center.add(request, withCompletionHandler: { (error) in
                    if let e = error {
                        print(e)
                        return
                    }
                    print("add local notification successfully. id = \(noticeIds[0]); content = \(content); trigger = \(trigger)")
                })

            case .location(let locate):
                content.title = NSString.localizedUserNotificationString(forKey: "Wake up!", arguments: nil)
                content.subtitle = NSString.localizedUserNotificationString(forKey: "Near home!", arguments: nil)
                content.body = NSString.localizedUserNotificationString(forKey: "It's time to get off!", arguments: nil)

                let region = CLCircularRegion(center: locate.coordinate, radius: 1000, identifier: "地点")
                region.notifyOnExit = false
                region.notifyOnEntry = true
                let trigger = UNLocationNotificationTrigger(region: region, repeats: false)

                // Create the request object.
                let request = UNNotificationRequest(identifier: noticeIds[1], content: content, trigger: trigger)
                center.add(request, withCompletionHandler: { (error) in
                    if let e = error {
                        print(e)
                    }
                })

                locationManager.requestWhenInUseAuthorization() //requestAlwaysAuthorization()
                CLGeocoder().reverseGeocodeLocation(locate, completionHandler: { (marks, error) in
                    if error == nil, let mark = marks?.first {
                        self.middleLabel.text = [mark.name, mark.locality].flatMap{$0}.joined(separator: ", ")
                    }
                    completion()
                })
            }
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
    func forward(for aSelector: Selector, sender: Any? = nil) {
        if let cv = hostView, let ip = cv.indexPath(for: self) {
            cv.delegate?.tableView?(cv, performAction: aSelector, forRowAt: ip, withSender: sender ?? self)
        }
    }
}
