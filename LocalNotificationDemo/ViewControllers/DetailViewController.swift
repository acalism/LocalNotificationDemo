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

    func configureView() {
        // Update the user interface for the detail item.

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }


    var detailItem: Event? {
        didSet {
            // Update the view.
            configureView()
        }
    }

    @IBAction func onSwitch(_ sender: UISwitch) {
        //
    }

}

