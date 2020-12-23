//
//  WQAudioSaveTool.swift
//  WQAudioEdit_Example
//
//  Created by 祺祺 on 2020/12/22.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation
class WQAudioSaveTool: NSObject {

    var editPlay:WQAudioEditPlay!
    var fileUrl:String!
    var actionTool:WQAudioEditAction!
    
    class func createSaveTool(editPlay:WQAudioEditPlay,fileUrl:String,actionTool:WQAudioEditAction) -> WQAudioSaveTool{
        let saveTool = WQAudioSaveTool.init()
        saveTool.editPlay = editPlay
        saveTool.fileUrl = fileUrl
        saveTool.actionTool = actionTool
        
        return saveTool
    }
    
    
    func beginSave() {
        var writeFile:AVAudioFile! = nil
        do {
            writeFile = try AVAudioFile.init(forWriting: URL.init(string: self.fileUrl)!, settings: [AVFormatIDKey:NSNumber.init(value: kAudioFormatLinearPCM),AVNumberOfChannelsKey:NSNumber.init(value: 2),AVSampleRateKey:NSNumber.init(value: self.actionTool.getSampleRate())])
        } catch  {
            
        }
        if writeFile == nil{
            return
        }
        
        
        
        
//
        self.editPlay.stop()
        self.editPlay.audioEngine.pause()
        for model:WQAudioEditModel in self.actionTool.editModelArray as! [WQAudioEditModel]{
            let buffer:AVAudioPCMBuffer = AVAudioPCMBuffer.init(pcmFormat: model.audioFile.processingFormat, frameCapacity: AVAudioFrameCount(model.endFrame - model.beginFrame))!
            model.audioFile.framePosition = model.beginFrame
            do {
                try model.audioFile.read(into: buffer, frameCount: AVAudioFrameCount(model.endFrame - model.beginFrame))
            } catch  {

            }
            do {
                try writeFile.write(from: buffer)
            } catch  {

            }
        }
        print("\(String(describing: self.fileUrl))")
        do {
            try self.editPlay.audioEngine.start()
        } catch  {

        }
        
        
        
        
    }
}
