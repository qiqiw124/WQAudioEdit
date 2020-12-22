//
//  WQAudioEditPlayTool.swift
//  WQAudioEdit_Example
//
//  Created by YUER on 2020/12/21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

protocol WQAudioEditPlayDelegate:NSObjectProtocol {
    func playProgress(tool:WQAudioEditPlay, currentframe:Int64,totalFrame:Int64,currentRate:Double)
    func playFinish(tool:WQAudioEditPlay)
}

class WQAudioEditPlay: NSObject {
    
    var audioEngine : AVAudioEngine!
    var playerNode  : AVAudioPlayerNode!
    var audioMixer  : AVAudioMixerNode!
    var pitchNode   : AVAudioUnitTimePitch!
    var loc         : Int64! = 0
    var segLength   : Int64 = 1024
    
    weak var delegate : WQAudioEditPlayDelegate?
    var editActionTool:WQAudioEditAction!
    
    var playStatus:AudioEditPlayStatusEnum = .none
    
    
    
    
    
    
    
    
    class func createPlayTool(editActionTool:WQAudioEditAction!) ->  WQAudioEditPlay{
        let playTool = WQAudioEditPlay.init()
        playTool.editActionTool = editActionTool
        playTool.setConfig()
        return playTool
    }
    
    private func setConfig() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch  let err as NSError{
            print(err.localizedDescription)
        }
        self.audioEngine = AVAudioEngine.init()
        self.playerNode = AVAudioPlayerNode.init()
        self.audioEngine.attach(self.playerNode)
        
        self.pitchNode = AVAudioUnitTimePitch.init()
        self.audioEngine.attach(self.pitchNode)
        self.audioEngine.connect(self.playerNode, to: self.pitchNode, format: self.pitchNode.outputFormat(forBus: 0))
        
        self.audioMixer = self.audioEngine.mainMixerNode
        self.audioEngine.connect(self.pitchNode, to: self.audioMixer, format: self.audioMixer.outputFormat(forBus: 0))
        
        do {
            try self.audioEngine.start()
        } catch let err as NSError{
            print(err.localizedDescription)
        }
    }
    
    private func scheduleSegment(fromFrame:Int64,length:Int64, com:@escaping AVAudioNodeCompletionHandler) {
        if self.editActionTool.editModelArray.count == 0{
            com()
            return
        }
        var beginModel : WQAudioEditModel! = nil
        var realBeginFrame:Int64 = 0
        var realLength:Int64 = 0
        for model:WQAudioEditModel in self.editActionTool.editModelArray as! [WQAudioEditModel]{
            let modelLength = model.endFrame - model.beginFrame
            if self.loc <= realLength + modelLength{
                realBeginFrame = self.loc - realLength + model.beginFrame
                beginModel = model
                break
            }else{
                realLength = realLength + modelLength
                
            }
            
        }
        if beginModel == nil{
            return
        }
        beginModel.seekFrame = realBeginFrame
        self.realScheduleSegment(fromFrame: realBeginFrame, length: self.segLength, model: beginModel) {
            com()
        }
        
        
    }
    private func realScheduleSegment(fromFrame:Int64,length:Int64,model:WQAudioEditModel, com:@escaping AVAudioNodeCompletionHandler){
        self.playerNode.scheduleSegment(model.audioFile, startingFrame:fromFrame, frameCount: AVAudioFrameCount(length), at: nil) {
            if self.playerNode.isPlaying == false{
                model.seekFrame = model.beginFrame
                return
            }
            self.loc = self.loc + length
            model.seekFrame = model.seekFrame + length
            
            self.playing(currentframe: self.loc, totalFrame: self.editActionTool.getTotalFrames())
            
            if(model.seekFrame >= model.endFrame){//结束
                
                com()
            }else if (model.endFrame - model.seekFrame > self.segLength){
                
                print("\(String(describing: model.seekFrame)),\(String(describing: model.endFrame))")
                self.realScheduleSegment(fromFrame: model.seekFrame, length: self.segLength, model: model) {
                    
                }
                
            }else if (model.endFrame - model.seekFrame <= self.segLength){//最后一片
                
                self.realScheduleSegment(fromFrame: model.seekFrame, length: model.endFrame - model.seekFrame, model: model) {
                    model.seekFrame = model.beginFrame
                    let index =  self.editActionTool.editModelArray.index(of: model)
                    if index < self.editActionTool.editModelArray.count - 1{
                        let nextModel = self.editActionTool.editModelArray.object(at: index + 1) as! WQAudioEditModel
                        self.realScheduleSegment(fromFrame: model.seekFrame, length: self.segLength, model: nextModel) {
                            com()
                        }
                    }else{
                        
                        com()
                    }
                }
            }
            
        }
    }
    
    
    
    
    private func playing(currentframe:Int64,totalFrame:Int64) {
        
        let currentDuration = Double(currentframe)/self.editActionTool.getSampleRate()
        print("\(currentDuration)")
        
        if self.delegate != nil{
            DispatchQueue.main.async {
                self.delegate?.playProgress(tool:self,currentframe: currentframe, totalFrame: totalFrame, currentRate: currentDuration)
            }
            
        }
    }

    
    
    //event
    func play() {
        if self.playStatus == .playing{
            return
        }
        self.playStatus = .playing
        self.scheduleSegment(fromFrame: self.loc, length: self.segLength) {
            if self.delegate != nil{
                self.delegate?.playFinish(tool: self)
            }
        }
        self.playerNode.play()
    }
    
    func seekFromFrame(fromFrame:Int64) {
        if(fromFrame > self.editActionTool.getTotalFrames()){
            return
        }
        self.stop()
        self.loc = fromFrame
        self.scheduleSegment(fromFrame: self.loc, length: self.segLength) {
            if self.delegate != nil{
                self.delegate?.playFinish(tool: self)
            }
        }
    }
    
    func play(fromFrame:Int64) {
        self.seekFromFrame(fromFrame: fromFrame)
        self.play()
        
    }
    func stop() {
        if self.playStatus == .stop || self.playStatus == .none{
            return
        }
        self.playerNode.stop()
        self.playStatus = .stop
        
        
        
    }
    
    
    
    //set
    func setVolume(volume:Float) {
        self.playerNode.volume = volume
    }
    func setRate(rate:Float) {
        self.pitchNode.rate = rate
    }
    
    
    
}
