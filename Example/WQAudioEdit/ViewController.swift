//
//  ViewController.swift
//  WQAudioEdit
//
//  Created by 01810452 on 12/17/2020.
//  Copyright (c) 2020 01810452. All rights reserved.
//

import UIKit

class ViewController: UIViewController ,WQAudioEditPlayDelegate,WQAudioSaveToolDelegate{
    
    

    @IBOutlet weak var playSlider: UISlider!
    var editActionTool:WQAudioEditAction!
    var editPlay:WQAudioEditPlay!
    override func viewDidLoad() {
        super.viewDidLoad()
        let fileUrl = Bundle.main.url(forResource: "simple-drum-beat1", withExtension: "mp3")
        self.editActionTool = WQAudioEditAction.createActionTool(fileUrl: fileUrl!)
        self.editPlay = WQAudioEditPlay.createPlayTool(editActionTool: self.editActionTool!)
        self.editPlay.delegate = self
        
        self.editActionTool.cutAction(firstFrame: 10161900/3, endFrame: 10161900/2)
        self.editActionTool.pasteAction(locFrame: 100000)
        
        self.playSlider.maximumValue = Float(self.editActionTool.getTotalFrames())
        self.playSlider.addTarget(self, action: #selector(touchUpSlide), for: .touchUpInside)
        self.playSlider.addTarget(self, action: #selector(touchInSlide), for: .touchDown)
        
        
        
    }
    @IBAction func playBtnClick(_ sender: Any) {
        self.editPlay.play(fromFrame: Int64(self.playSlider.value))
    }
    @IBAction func stopPlayBtnClick(_ sender: Any) {
        self.editPlay.stop()
    }
    @IBAction func saveFileBtnClick(_ sender: Any) {
        let save = WQAudioSaveTool.init(play: self.editPlay.audioEngine, play: self.editPlay.playerNode, saveFileUrl: self.filePath(), actionTool: self.editActionTool)
        save.delegate = self
        save.beginSave()
    }
    
    @objc func touchInSlide() {
        self.editPlay.stop()
    }
    @objc func touchUpSlide() {
        self.editPlay.play(fromFrame: Int64(self.playSlider.value))
    }
    
    
    //WQAudioEditPlayDelegate
    func playProgress(tool: WQAudioEditPlay, currentframe: Int64, totalFrame: Int64, currentRate: Double) {
        self.playSlider.setValue(Float(currentframe), animated: true)
    }
    func playFinish(tool: WQAudioEditPlay) {
      print("播放完毕")
    }
    
    //WQAudioSaveToolDelegate
    func saveTool(_ saveTool: WQAudioSaveTool, saveFinishPath filePath: String) {
        print("\(filePath)")
    }
    
    func saveTool(_ saveTool: WQAudioSaveTool, saveProgress progress: Float, error: Error?) {
        print("\(progress)")
    }
    
    
    func filePath() -> String {
        let documentsFolders = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        let fileName = "/test.caf"
        let path = documentsFolders?.appending(fileName)
        return (path ?? "") as String
    }

}

