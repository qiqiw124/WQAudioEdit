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
        
        for model:WQAudioEditModel in self.actionTool.editModelArray as! [WQAudioEditModel]{

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            let reverb = AVAudioUnitReverb()

            engine.attach(player)
            engine.attach(reverb)

            // Set the desired reverb parameters.
            reverb.loadFactoryPreset(.mediumHall)
            reverb.wetDryMix = 50

            // Connect the nodes.
            engine.connect(player, to: reverb, format: model.audioFile.processingFormat)
            engine.connect(reverb, to: engine.mainMixerNode, format: model.audioFile.processingFormat)
            
            player.scheduleSegment(model.audioFile, startingFrame: model.beginFrame, frameCount: AVAudioFrameCount(model.endFrame - model.beginFrame), at: nil, completionHandler: nil)

            do {
                // The maximum number of frames the engine renders in any single render call.
                let maxFrames: AVAudioFrameCount = 4096
                try engine.enableManualRenderingMode(.offline, format: model.audioFile.processingFormat,
                                                     maximumFrameCount: maxFrames)
            } catch {
                fatalError("Enabling manual rendering mode failed: \(error).")
            }

            do {
                try engine.start()
                player.play()
            } catch {
                fatalError("Unable to start audio engine: \(error).")
            }

            // The output buffer to which the engine renders the processed data.
            let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat,
                                          frameCapacity: engine.manualRenderingMaximumFrameCount)!


            while engine.manualRenderingSampleTime < model.endFrame - model.beginFrame {
                do {
                    let frameCount = model.endFrame - model.beginFrame - engine.manualRenderingSampleTime
                    let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)

                    let status = try engine.renderOffline(framesToRender, to: buffer)

                    switch status {

                    case .success:
                        // The data rendered successfully. Write it to the output file.
                        try writeFile.write(from: buffer)

                    case .insufficientDataFromInputNode:
                        // Applicable only when using the input node as one of the sources.
                        break

                    case .cannotDoInCurrentContext:
                        // The engine couldn't render in the current render call.
                        // Retry in the next iteration.
                        break

                    case .error:
                        // An error occurred while rendering the audio.
                        fatalError("The manual rendering failed.")
                    }
                } catch {
                    fatalError("The manual rendering failed: \(error).")
                }
            }

            // Stop the player node and engine.
            player.stop()
            engine.stop()
            
            
        }
        
        
//
//        self.editPlay.stop()
//        self.editPlay.audioEngine.pause()
//        do {
//            try self.editPlay.audioEngine.enableManualRenderingMode(.offline, format: self.actionTool.getFormate(), maximumFrameCount: AVAudioFrameCount(self.actionTool.getTotalFrames()))
//        } catch  {
//
//        }
//
//        for model:WQAudioEditModel in self.actionTool.editModelArray as! [WQAudioEditModel]{
//            let buffer:AVAudioPCMBuffer = AVAudioPCMBuffer.init(pcmFormat: model.audioFile.processingFormat, frameCapacity: AVAudioFrameCount(model.endFrame - model.beginFrame))!
//            model.audioFile.framePosition = model.beginFrame
//            do {
//                try model.audioFile.read(into: buffer, frameCount: AVAudioFrameCount(model.endFrame - model.beginFrame))
//            } catch  {
//
//            }
////            do {
////                let statu = try self.editPlay.audioEngine.renderOffline(AVAudioFrameCount(model.endFrame - model.beginFrame), to: buffer)
////                print("\(statu)")
////            } catch  {
////
////            }
//            do {
//                try writeFile.write(from: buffer)
//            } catch  {
//
//            }
//        }
//        print("\(String(describing: self.fileUrl))")
//        do {
//            try self.editPlay.audioEngine.start()
//        } catch  {
//
//        }
        
        
        
        
    }
}
