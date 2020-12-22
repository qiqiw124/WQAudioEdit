//
//  WQAudioSaveTool.h
//  WQAudioEdit_Example
//
//  Created by YUER on 2020/12/21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@class WQAudioEditAction;
@class WQAudioSaveTool;
@protocol WQAudioSaveToolDelegate <NSObject>
-(void)saveTool:(WQAudioSaveTool *)saveTool saveProgress:(float)progress error:(NSError *__nullable)error;
-(void)saveTool:(WQAudioSaveTool *)saveTool saveFinishPath:(NSString *)filePath;

@end
@interface WQAudioSaveTool : NSObject

@property(nonatomic,weak)id<WQAudioSaveToolDelegate>delegate;

+(WQAudioSaveTool *)saveToolWithPlay:(AVAudioEngine *)engine
                            playNode:(AVAudioPlayerNode *)playNode
                         saveFileUrl:(NSString *)fileUrl
                          actionTool:(WQAudioEditAction *)actionTool;
-(void)beginSave;
@end

NS_ASSUME_NONNULL_END
