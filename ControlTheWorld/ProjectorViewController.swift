//
//  ViewController.swift
//  ControlTheWorld
//
//  Created by 孟康 on 2/11/19.
//  Copyright © 2019 kang. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ProjectorViewController: UIViewController {
    let delegate = UIApplication.shared.delegate as! AppDelegate
    weak var piResponseListener: ListenerRegistration?
    
    @IBOutlet weak var piStatusLabel: UILabel!
    @IBOutlet weak var checkStatusButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.piResponseListener = delegate.db.collection("PiResponse").addSnapshotListener {
            querySnapshot, error in
            guard let snapshot = querySnapshot else {
                print("Error fetching document: \(error!)")
                self.checkStatusButton.isEnabled = true
                return
            }
            snapshot.documentChanges.forEach { diff in
                if diff.type == .modified {
                    print("Modified: \(diff.document.data())")
                    self.checkStatusButton.isEnabled = true
                    let t = diff.document.data()["timestamp"] as! Timestamp
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
                    dateFormatter.timeZone = .current
                    self.piStatusLabel.text = "Connected: \(dateFormatter.string(from: t.dateValue()))"
                }
            }
        }
    }

    @IBAction func checkStatus(_ sender: Any) {
        self.checkStatusButton.isEnabled = false
        self.piStatusLabel.text = "Checking"
        delegate.db.collection("AppRequest").document("appRequest").setData([
            "timestamp": FieldValue.serverTimestamp()
        ]) {
            err in
            if let err = err {
                print("Error writing document: \(err)")
                self.piStatusLabel.text = "Error"
                self.checkStatusButton.isEnabled = true
                return
            }
        }
        
    }
    
    @IBAction func clickOn(_ sender: Any) {
        executeCommand(device: "projector", command: "KEY_POWER")
    }
    
    @IBAction func clickOff(_ sender: Any) {
        executeCommand(device: "projector", command: "OFF")
    }
    
    @IBAction func clickUp(_ sender: Any) {
        executeCommand(device: "projector", command: "Cursor_UP")
        
    }
    
    @IBAction func clickDown(_ sender: Any) {
        executeCommand(device: "projector", command: "Cursor_DOWN")
    }
    
    @IBAction func clickLeft(_ sender: Any) {
        executeCommand(device: "projector", command: "Cursor_LEFT")
    }
    
    @IBAction func clickRight(_ sender: Any) {
        executeCommand(device: "projector", command: "Cursor_RIGHT")
    }
    
    @IBAction func clickEnter(_ sender: Any) {
        executeCommand(device: "projector", command: "KEY_ENTER")
    }
    
    @IBAction func clickExit(_ sender: Any) {
        executeCommand(device: "projector", command: "KEY_EXIT")
    }
    
    @IBAction func clickMenu(_ sender: Any) {
        executeCommand(device: "projector", command: "KEY_MENU")
    }
    
    func executeCommand(device: String, command: String) {
        delegate.db.collection("CurrentCommand").document("current").setData([
            "device": device,
            "command": command,
            "timestamp": FieldValue.serverTimestamp()
        ]) {
            err in
            if let err = err {
                print("Error writing document: \(err)")
                return
            }
        }
    }
    
}

