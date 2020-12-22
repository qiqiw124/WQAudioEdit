//
//  WQAudioEditEnum.swift
//  WQAudioEdit_Example
//
//  Created by YUER on 2020/12/18.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
//操作状态
public enum AudioEditActionEnum : NSInteger {
    case none       = 0 //无
    case copy       = 1 //复制
    case paste      = 2 //粘贴
    case cut        = 3 //剪切
}

//播放状态
public enum AudioEditPlayStatusEnum : NSInteger {
    case none           = 0 //无
    case playing        = 1 //播放中
    case stop           = 2 //停止
}




class WQAudioEditEnum: NSObject {

}
