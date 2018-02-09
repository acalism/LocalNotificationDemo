//
//  DetailViewController.swift
//  LocalNotificationDemo
//
//  Created by donaldsong(宋黎明) on 2018-2-5.
//  Copyright © 2018 donaldsong(宋黎明). All rights reserved.
//

import UIKit

class DetailViewController: UITableViewController {

    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var rightSwitch: UISwitch!

    func configureView() {
        // Update the user interface for the detail item.
        timePicker.date = detailItem?.timestamp ?? Date()
        rightLabel.text = detailItem?.sound
        rightSwitch.isOn = detailItem?.isEnabled ?? true
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let item0 = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onDone))
        let item1 = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(onCancel))
        navigationItem.rightBarButtonItems = [item0, item1] // 从左到左

        configureView()
    }


    var detailItem: Event?

    @IBAction func onSwitch(_ sender: UISwitch) {
        //
    }

    @objc
    func onCancel() {
        //
    }

    @objc
    func onDone() {
        //
    }
}

