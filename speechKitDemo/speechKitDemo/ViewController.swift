//
//  ViewController.swift
//  speechKitDemo
//
//  Created by Minewtech on 2018/10/18.
//  Copyright © 2018 Minewtech. All rights reserved.
//

import UIKit
import Speech
import SnapKit

class ViewController: UIViewController {

    var recordLabel : UILabel!
    var textView : UITextView!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SFSpeechRecognizer.requestAuthorization { (status) in
            if status == .authorized {
                print("验证成功。")
            }
            else
            {
                print(status)
            }
        }
        
        let recognizer = UILongPressGestureRecognizer.init(target: self, action: #selector(start(recognizer:)))
        let backView = UIView()
        backView.backgroundColor = UIColor.orange
        backView.addGestureRecognizer(recognizer)
        self.view.addSubview(backView)
        backView.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-50)
            make.size.equalTo(CGSize.init(width: 100, height: 100))
        }
        
        recordLabel = UILabel.init()
        recordLabel.text = "开始录音"
        backView.addSubview(recordLabel)
        recordLabel.snp.makeConstraints { (make) in
            make.center.equalTo(backView)
        }
        
        textView = UITextView.init()
        textView.backgroundColor = UIColor.brown
        self.view.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view).offset(50)
            make.left.equalTo(self.view).offset(20)
            make.right.equalTo(self.view).offset(-20)
            make.height.equalTo(200)
        }
        
    }

    func stopRecording() -> Void {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.inputNode.reset()
            audioEngine.stop()
            
            recognitionRequest?.endAudio()
            recognitionRequest = nil
            recognitionTask?.cancel()
            recognitionTask = nil
            recordLabel.text = "开始录音"
        }
        
    }
    
    @objc func start(recognizer:UILongPressGestureRecognizer) -> Void {
        
        switch recognizer.state {
            case .began:
                print("began")
                break
            case .cancelled:
                print("cancel")
                return
    //            break
            case .changed:
                return
    //            break
            case .ended:
                print("ended")
                self.stopRecording()
                return
    //            break
            case .failed:
                print("failed")
                return
    //            break
            case .possible:
                print("possible")
                return
    //            break
            default:
                print("none")
                return
    //            break
        }
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.duckOthers)
            try audioSession.setActive(true, options: AVAudioSession.SetActiveOptions.notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer!.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                self.audioEngine.inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
            }
        })
        
        let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        recordLabel.text = "录音中..."
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        textView.resignFirstResponder()
    }

}

