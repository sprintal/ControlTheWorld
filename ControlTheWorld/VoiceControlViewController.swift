//
//  VoiceControlViewController.swift
//  ControlTheWorld
//
//  Created by Kang Meng on 4/11/19.
//  Copyright © 2019 kang. All rights reserved.
//

import UIKit
import Speech
import FirebaseFirestore

class VoiceControlViewController: UIViewController, SFSpeechRecognizerDelegate {
    let delegate = UIApplication.shared.delegate as! AppDelegate
    let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-AU"))
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let audioEngine = AVAudioEngine()
    
    @IBOutlet weak var voiceLabel: UILabel!
    @IBOutlet weak var voiceControlButton: UIButton!
    @IBOutlet weak var commandLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        voiceControlButton.isEnabled = false
        speechRecognizer!.delegate = self
        voiceLabel.text = ""
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            var isButtonEnabled = false
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech")
            case .restricted:
                isButtonEnabled = false
                print("Speech restricted on device")
            case .notDetermined:
                isButtonEnabled = false
            }
            
            OperationQueue.main.addOperation {
                self.voiceControlButton.isEnabled = isButtonEnabled
            }
            
            
        }
        // Do any additional setup after loading the view.
    }
    
    func startRecording() {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object.")
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            var isFinal = false
            if result != nil {
                self.voiceLabel.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                self.findCommand(command: self.voiceLabel.text!)
            } else {
                self.voiceLabel.text = "Not recognized"
            }
            if (error != nil) || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.voiceControlButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine could not start because of an error")
        }
        
        voiceLabel.text = "Recording..."
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            voiceControlButton.isEnabled = true
        } else {
            voiceControlButton.isEnabled = false
        }
    }
    
    @IBAction func clickVoiceControl(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            voiceControlButton.isEnabled = false
            voiceControlButton.setTitle("Start Recording", for: .normal)
            
            if voiceLabel.text != "Not recognized" && voiceLabel.text != nil {
                
            }
        } else {
            startRecording()
            voiceControlButton.setTitle("Stop Recording", for: .normal)
        }
    }
    
    func findCommand(command: String) {
        self.commandLabel.text = "Finding command matches \"\(command.lowercased())\" on Firestore..."
        let query = delegate.db.collection("Commands").whereField("voice", isEqualTo: command.lowercased())
        query.getDocuments() { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else if (querySnapshot?.documents.count)! > 0 {
                let commandDoc = querySnapshot?.documents[0]
                self.commandLabel.text = "Requesting the execution of command \"\(command.lowercased())\""
                self.executeCommand(device: commandDoc?.data()["device"] as! String, command: commandDoc?.data()["remote"] as! String)
            } else {
                self.commandLabel.text = "No command matches \"\(command.lowercased())\" found"
                return
            }
            
        }
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
                self.commandLabel.text = "Command \"\(command)\" failed to execute"
                return
            }
        }
        self.commandLabel.text = "Command \"\(command)\"executed"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    
}
