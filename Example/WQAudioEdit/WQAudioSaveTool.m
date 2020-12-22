//
//  WQAudioSaveTool.m
//  WQAudioEdit_Example
//
//  Created by YUER on 2020/12/21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

#import "WQAudioSaveTool.h"
#import "WQAudioEdit_Example-Swift.h"

@interface WQAudioSaveTool()
@property(nonatomic,strong)AVAudioEngine * engine;
@property(nonatomic,strong)AVAudioPlayerNode * playNode;
@property(nonatomic,strong)WQAudioEditAction * actionTool;
@property(nonatomic,copy)NSString * fileUrl;
@end

@implementation WQAudioSaveTool

+(WQAudioSaveTool *)saveToolWithPlay:(AVAudioEngine *)engine
                            playNode:(AVAudioPlayerNode *)playNode
                         saveFileUrl:(NSString *)fileUrl
                          actionTool:(WQAudioEditAction *)actionTool{
    WQAudioSaveTool * tool = [[WQAudioSaveTool alloc]init];
    tool.engine         = engine;
    tool.playNode       = playNode;
    tool.fileUrl        = fileUrl;
    tool.actionTool     = actionTool;
    return tool;
}


-(void)beginSave{
    [self renderAudioAndWriteToFile];
}



- (NSString *)renderAudioAndWriteToFile {
    
    AVAudioOutputNode *outputNode = self.engine.outputNode;
    AudioStreamBasicDescription const *audioDescription = [outputNode outputFormatForBus:0].streamDescription;
    NSString *path = self.fileUrl;
    ExtAudioFileRef audioFile = [self createAndSetupExtAudioFileWithASBD:audioDescription andFilePath:path];
    if (!audioFile)
        return nil;
    NSUInteger lengthInFrames = [self.actionTool getTotalFrames];
    const NSUInteger kBufferLength = 1024;
    AudioBufferList *bufferList = AEAllocateAndInitAudioBufferList(*audioDescription, kBufferLength);
    AudioTimeStamp timeStamp;
    memset (&timeStamp, 0, sizeof(timeStamp));
    timeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    OSStatus status = noErr;
    
    for(WQAudioEditModel * model in self.actionTool.editModelArray){
        [self.engine startAndReturnError:nil];
        [self.playNode stop];
        NSInteger begin = [model.beginFrameStr integerValue];
        NSInteger end = [model.endFrameStr integerValue];
        [self.playNode scheduleSegment:model.audioFile startingFrame:begin frameCount:(end - begin) atTime:nil completionHandler:nil];
        [self.playNode play];
        [self.engine pause];
        
        for (NSUInteger i = kBufferLength; i < end - begin; i += kBufferLength){
            status = [self renderToBufferList:bufferList writeToFile:audioFile bufferLength:kBufferLength timeStamp:&timeStamp];
            if(self.delegate && [self.delegate respondsToSelector:@selector(saveTool:saveProgress:error:)]){
                [self.delegate saveTool:self saveProgress:timeStamp.mSampleTime/lengthInFrames error:nil];
            }
            if (status != noErr)
                break;
        }
        if (status != noErr)
            break;
    }
    if (status == noErr && timeStamp.mSampleTime < lengthInFrames) {
        int restBufferLength = (int) (lengthInFrames - timeStamp.mSampleTime);
        AudioBufferList *restBufferList = AEAllocateAndInitAudioBufferList(*audioDescription, restBufferLength);
        status = [self renderToBufferList:restBufferList writeToFile:audioFile bufferLength:restBufferLength timeStamp:&timeStamp];
        AEFreeAudioBufferList(restBufferList);
    }
    SInt64 fileLengthInFrames;
    UInt32 size = sizeof(SInt64);
    ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &size, &fileLengthInFrames);
    AEFreeAudioBufferList(bufferList);
    ExtAudioFileDispose(audioFile);
    if (status == noErr)
        if(self.delegate && [self.delegate respondsToSelector:@selector(saveTool:saveFinishPath:)]){
            [self.delegate saveTool:self saveFinishPath:path];
        }
        
    else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(saveTool:saveProgress:error:)]){
            NSError * error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            [self.delegate saveTool:self saveProgress:0 error:error];
        }
    }
    [self.engine startAndReturnError:nil];
    return path;
}

- (ExtAudioFileRef)createAndSetupExtAudioFileWithASBD:(AudioStreamBasicDescription const *)audioDescription
                                          andFilePath:(NSString *)path {
    AudioStreamBasicDescription destinationFormat;
    memset(&destinationFormat, 0, sizeof(destinationFormat));
    destinationFormat.mChannelsPerFrame = audioDescription->mChannelsPerFrame;
    destinationFormat.mSampleRate = audioDescription->mSampleRate;
    destinationFormat.mFormatID = kAudioFormatMPEG4AAC;
    ExtAudioFileRef audioFile;
    OSStatus status = ExtAudioFileCreateWithURL(
            (__bridge CFURLRef) [NSURL fileURLWithPath:path],
                                                kAudioFileCAFType,
            &destinationFormat,
            NULL,
            kAudioFileFlags_EraseFile,
            &audioFile
    );
    if (status != noErr) {
        NSLog(@"Can not create ext audio file");
        return nil;
    }
    UInt32 codecManufacturer = kAppleSoftwareAudioCodecManufacturer;
    status = ExtAudioFileSetProperty(
            audioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManufacturer
    );
    status = ExtAudioFileSetProperty(
            audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), audioDescription
    );
    status = ExtAudioFileWriteAsync(audioFile, 0, NULL);
    if (status != noErr) {
        NSLog(@"Can not setup ext audio file");
        return nil;
    }
    return audioFile;
}

- (OSStatus)renderToBufferList:(AudioBufferList *)bufferList
                   writeToFile:(ExtAudioFileRef)audioFile
                  bufferLength:(NSUInteger)bufferLength
                     timeStamp:(AudioTimeStamp *)timeStamp {
    [self clearBufferList:bufferList];
    AudioUnit outputUnit = self.engine.outputNode.audioUnit;
    OSStatus status = AudioUnitRender(outputUnit, 0, timeStamp, 0, bufferLength, bufferList);
    if (status != noErr) {
        NSLog(@"Can not render audio unit");
        return status;
    }
    timeStamp->mSampleTime += bufferLength;
    status = ExtAudioFileWrite(audioFile, bufferLength, bufferList);
    if (status != noErr)
        NSLog(@"Can not write audio to file");
    return status;
}

- (void)clearBufferList:(AudioBufferList *)bufferList {
    for (int bufferIndex = 0; bufferIndex < bufferList->mNumberBuffers; bufferIndex++) {
        memset(bufferList->mBuffers[bufferIndex].mData, 0, bufferList->mBuffers[bufferIndex].mDataByteSize);
    }
}
AudioBufferList *AEAllocateAndInitAudioBufferList(AudioStreamBasicDescription audioFormat, int frameCount) {
    int numberOfBuffers = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? audioFormat.mChannelsPerFrame : 1;
    int channelsPerBuffer = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : audioFormat.mChannelsPerFrame;
    int bytesPerBuffer = audioFormat.mBytesPerFrame * frameCount;
    AudioBufferList *audio = malloc(sizeof(AudioBufferList) + (numberOfBuffers - 1) * sizeof(AudioBuffer));
    if (!audio) {
        return NULL;
    }
    audio->mNumberBuffers = numberOfBuffers;
    for (int i = 0; i < numberOfBuffers; i++) {
        if (bytesPerBuffer > 0) {
            audio->mBuffers[i].mData = calloc(bytesPerBuffer, 1);
            if (!audio->mBuffers[i].mData) {
                for (int j = 0; j < i; j++) free(audio->mBuffers[j].mData);
                free(audio);
                return NULL;
            }
        } else {
            audio->mBuffers[i].mData = NULL;
        }
        audio->mBuffers[i].mDataByteSize = bytesPerBuffer;
        audio->mBuffers[i].mNumberChannels = channelsPerBuffer;
    }
    return audio;
}

void AEFreeAudioBufferList(AudioBufferList *bufferList) {
    for (int i = 0; i < bufferList->mNumberBuffers; i++) {
        if (bufferList->mBuffers[i].mData) free(bufferList->mBuffers[i].mData);
    }
    free(bufferList);
}
@end
