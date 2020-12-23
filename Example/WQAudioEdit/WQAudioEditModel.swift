//
//  WQAudioEditModel.swift
//  WQAudioEdit_Example
//
//  Created by YUER on 2020/12/18.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import AVFoundation

@objcMembers
class WQAudioEditModel: NSObject {
    //开始
    var beginFrame:Int64! = 0
    //结束
    var endFrame:Int64! = 0
    //从哪个位置开始播放
    var seekFrame:Int64! = 0
    
    var fileUrl:URL!
    
    var audioFile:AVAudioFile!
    
    var editAction:AudioEditActionEnum! = AudioEditActionEnum.none
    
    class func model(bgFrame:Int64,edFrame:Int64,editAction:AudioEditActionEnum,fileUrl:URL) -> WQAudioEditModel {
        let model : WQAudioEditModel = WQAudioEditModel.init()
        model.beginFrame    = bgFrame
        model.endFrame      = edFrame
        model.seekFrame     = bgFrame
        model.editAction    = editAction
        model.fileUrl       = fileUrl
        do {
            try model.audioFile     = AVAudioFile.init(forReading: fileUrl)
        } catch  {
            
        }
        return model
    }
    
    func reinitModel() -> WQAudioEditModel {
        let model = WQAudioEditModel.model(bgFrame: self.beginFrame, edFrame: self.endFrame, editAction: self.editAction,fileUrl: self.audioFile.url)
        return model
    }
    
    
    
}
