//
//  WQAudioEditAction.swift
//  WQAudioEdit_Example
//
//  Created by YUER on 2020/12/18.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class WQAudioEditAction: NSObject {
    @objc var editModelArray:NSMutableArray!
    private var copyArray:NSMutableArray!
    private var defaultUrl :URL!
    
    
    
    
    class func createActionTool(fileUrl:URL) -> WQAudioEditAction{
        let actionTool = WQAudioEditAction.init()
        actionTool.defaultUrl = fileUrl
        actionTool.config()
        return actionTool
    }
    
    
    private func config() {
        self.editModelArray = NSMutableArray.init()
        let firstModel = WQAudioEditModel.model(bgFrame: 0, edFrame: 0, editAction: .none,fileUrl: self.defaultUrl)
        firstModel.endFrame = firstModel.audioFile.length
        firstModel.endFrameStr = "\(firstModel.audioFile.length)" as NSString
        self.editModelArray.add(firstModel)
        
    }
    
    func copyAction(firstFrame:Int64,endFrame:Int64) {
        self.copyArray = NSMutableArray.init()
        let cpLength = endFrame - firstFrame
        
        var realLoc:Int64 = 0
        
        
        if self.editModelArray.count == 0{
            let aeModel:WQAudioEditModel = WQAudioEditModel.model(bgFrame: firstFrame, edFrame: endFrame, editAction: .copy,fileUrl: self.defaultUrl)
            self.copyArray.add(aeModel)
        }else{
            for model in self.editModelArray {
                let aeModel = model as! WQAudioEditModel
                let modelLength = aeModel.endFrame - aeModel.beginFrame
                
                if realLoc + modelLength > firstFrame{//firstFrame在此model中
                    if realLoc + modelLength >= endFrame{//endFrame也在model中
                        let cpFirstFrame:Int64 = firstFrame - realLoc + aeModel.beginFrame
                        let cpEndFrame:Int64 = cpFirstFrame + cpLength
                        let cpModel = WQAudioEditModel.model(bgFrame: cpFirstFrame, edFrame: cpEndFrame, editAction: .copy,fileUrl: aeModel.fileUrl)
                        self.copyArray.add(cpModel.reinitModel())
                        break
                    }else if(realLoc + modelLength < endFrame){//endframe在下一个model中
                        let cpFirstFrame:Int64 = firstFrame - realLoc + aeModel.beginFrame
                        //先添加firstFrame所在的model的部分
                        self.copyArray.add(WQAudioEditModel.model(bgFrame: cpFirstFrame, edFrame: aeModel.endFrame, editAction: .copy,fileUrl: aeModel.fileUrl))
                        //获取endframe
                        let index = self.editModelArray.index(of: model)
                        let lastArray = self.editModelArray.subarray(with: NSMakeRange(index + 1, self.editModelArray.count - index - 1))
                        
                        for lastModel in lastArray{
                            let lastM = lastModel as! WQAudioEditModel
                            let lastMLength = lastM.endFrame - lastM.beginFrame
                            //找endFrame的所在model
                            if realLoc + lastMLength > endFrame{
                                self.copyArray.add(WQAudioEditModel.model(bgFrame: lastM.beginFrame, edFrame: endFrame - realLoc + lastM.beginFrame, editAction: .copy,fileUrl: aeModel.fileUrl))
                                break;
                            }else{
                                realLoc = realLoc + lastMLength
                                self.copyArray.add(lastM.reinitModel())
                            }
                            
                            
                        }
                        break
                        
                    }
                    
                }else{
                    realLoc = modelLength + realLoc
                }

                
            }
        }
        
    }
    
    func pasteAction(locFrame:Int64) {
        if self.copyArray.count > 0{
            var realLoc:Int64 = 0
            let forModel = NSArray.init(array: self.editModelArray)
            for model in forModel {
                let aeModel = model as! WQAudioEditModel
                let modelLength = aeModel.endFrame - aeModel.beginFrame
                
                if realLoc + modelLength > locFrame{//寻找位置，位置在model的中部，分割model
                    let index = self.editModelArray.index(of: model)
                    if realLoc == locFrame{//起始点相同，则直接插入到前面
                        let lastarray = self.editModelArray.subarray(with: NSMakeRange(index, self.editModelArray.count - index))
                        self.editModelArray.removeObjects(in: lastarray)
                        self.editModelArray.addObjects(from: self.copyArray as! [Any])
                        self.editModelArray.addObjects(from: lastarray)
                    }else{
                        let newModel1 = WQAudioEditModel.model(bgFrame: aeModel.beginFrame, edFrame: locFrame - realLoc + aeModel.beginFrame, editAction: .none,fileUrl: aeModel.fileUrl)
                        self.editModelArray.replaceObject(at: index, with: newModel1)
                        let lastarray = self.editModelArray.subarray(with: NSMakeRange(index + 1, self.editModelArray.count - index - 1))
                        self.editModelArray.removeObjects(in: lastarray)
                        let newModel2 = WQAudioEditModel.model(bgFrame: locFrame - realLoc + aeModel.beginFrame, edFrame: aeModel.endFrame, editAction: .none,fileUrl: aeModel.fileUrl)
                        self.editModelArray.addObjects(from: self.copyArray as! [Any])
                        self.editModelArray.add(newModel2)
                        self.editModelArray.addObjects(from: lastarray)
                    }
                    
                    
                    break
                }else if realLoc + modelLength == locFrame{//寻找位置，位置在model的尾部，从其后插入位置
                    let index = self.editModelArray.index(of: model)
                    let lastarray = self.editModelArray.subarray(with: NSMakeRange(index + 1, self.editModelArray.count - index - 1))
                    self.editModelArray.removeObjects(in:lastarray)
                    self.editModelArray.addObjects(from: self.copyArray as! [Any])
                    self.editModelArray.addObjects(from: lastarray)
                    
                    break
                }else{
                    realLoc = realLoc + modelLength
                }
                
            }
            
        }
    }
    
    
    func cutAction(firstFrame:Int64,endFrame:Int64) {
        self.copyAction(firstFrame: firstFrame, endFrame: endFrame)
        var realLoc:Int64 = 0
        let forModel = NSArray.init(array: self.editModelArray)
        for model in forModel {
            let aeModel = model as! WQAudioEditModel
            let modelLength = aeModel.endFrame - aeModel.beginFrame
            
            if realLoc + modelLength > firstFrame{//firstFrame在此model中
                let index = self.editModelArray.index(of: model)
                if realLoc + modelLength >= endFrame{//endFrame也在model中
                    if realLoc == aeModel.beginFrame{//起点相同，直接剪切
                        if realLoc + modelLength != endFrame{
                            let newModel2 = WQAudioEditModel.model(bgFrame: endFrame - realLoc, edFrame: aeModel.endFrame, editAction: .none,fileUrl: aeModel.fileUrl)
                            self.editModelArray.replaceObject(at: index, with: newModel2)
                        }
                    }else{
                        let newModel1 = WQAudioEditModel.model(bgFrame: aeModel.beginFrame, edFrame: firstFrame - realLoc, editAction: .none,fileUrl: aeModel.fileUrl)
                        self.editModelArray.replaceObject(at: index, with: newModel1)
                        if realLoc + modelLength != endFrame{
                            let newModel2 = WQAudioEditModel.model(bgFrame: endFrame - realLoc, edFrame: aeModel.endFrame, editAction: .none,fileUrl: aeModel.fileUrl)
                            self.editModelArray.insert(newModel2, at: index + 1)
                        }
                    }
                    break
                }else if(realLoc + modelLength < endFrame){//endframe在下一个model中
                    let cutFirstFrame:Int64 = firstFrame - realLoc + aeModel.beginFrame
                    let newFirstModel = WQAudioEditModel.model(bgFrame: aeModel.beginFrame, edFrame: cutFirstFrame, editAction: .none,fileUrl: aeModel.fileUrl)
                    self.editModelArray.replaceObject(at: index, with: newFirstModel)
                
                    //获取endframe
                    let index = self.editModelArray.index(of: model)
                    let lastArray = self.editModelArray.subarray(with: NSMakeRange(index+1, self.editModelArray.count - index - 1))
                    for lastModel in lastArray{
                        let lastM = lastModel as! WQAudioEditModel
                        let lastMLength = lastM.endFrame - lastM.beginFrame
                        //找endFrame的所在model
                        if realLoc + lastMLength > endFrame{
                            //创建新的model，去掉截取的部分
                            let newEndModel = WQAudioEditModel.model(bgFrame: endFrame - realLoc + lastM.beginFrame, edFrame: lastM.endFrame, editAction: .none,fileUrl: aeModel.fileUrl)
                            let cutIndex = self.editModelArray.index(of: lastM)
                            self.editModelArray.replaceObject(at: cutIndex, with: newEndModel)
                            break;
                        }else{
                            realLoc = realLoc + lastMLength
                            self.editModelArray.remove(lastModel)
                        }
                        
                        
                    }
                    break
                    
                }
                
            }else{
                realLoc = modelLength + realLoc
            }

            
        }
        
    }
    
    
    
    
    //get
    @objc func getTotalFrames() -> Int64{
        var length : Int64 = 0
        for model in self.editModelArray {
            let edModel = model as! WQAudioEditModel
            length = Int64(length + edModel.endFrame - edModel.beginFrame)
        }
        return length
    }
    func getSampleRate() -> Double {//默认以首个为准
        if self.editModelArray.count > 0{
            let model = self.editModelArray.firstObject as! WQAudioEditModel
            return model.audioFile.fileFormat.sampleRate
        }
        return 44100
    }
    func getDuration() -> Double {
        return Double(self.getTotalFrames()) / self.getSampleRate()
    }
    
    
    
}
