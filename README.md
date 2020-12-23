# WQAudioEdit

[![CI Status](https://img.shields.io/travis/01810452/WQAudioEdit.svg?style=flat)](https://travis-ci.org/01810452/WQAudioEdit)
[![Version](https://img.shields.io/cocoapods/v/WQAudioEdit.svg?style=flat)](https://cocoapods.org/pods/WQAudioEdit)
[![License](https://img.shields.io/cocoapods/l/WQAudioEdit.svg?style=flat)](https://cocoapods.org/pods/WQAudioEdit)
[![Platform](https://img.shields.io/cocoapods/p/WQAudioEdit.svg?style=flat)](https://cocoapods.org/pods/WQAudioEdit)

## Example
本demo采用audioEngine进行开发
```
包含剪切，复制，粘贴，并进行操作后的播放和保存
```
以下方式创建编辑工具
```
let fileUrl = Bundle.main.url(forResource: "simple-drum-beat1", withExtension: "mp3")
self.editActionTool = WQAudioEditAction.createActionTool(fileUrl: fileUrl!)
```
以下方式创建播放器
```
self.editPlay = WQAudioEditPlay.createPlayTool(editActionTool: self.editActionTool!)
self.editPlay.delegate = self
```
编辑调用中传入的frame参数均为以总流长度为基准的位置

剪切
```
self.editActionTool.cutAction(firstFrame: 10161900/3, endFrame: 10161900/2)
```
粘贴
```
self.editActionTool.pasteAction(locFrame: 100000)
```
复制
```
self.editActionTool.copyAction(firstFrame: 10161900/3, endFrame: 10161900/2)
```
保存编辑后的音频
```
let save = WQAudioSaveTool.createSaveTool(editPlay: self.editPlay, fileUrl: self.filePath(), actionTool: self.editActionTool)
save.beginSave()
```
有兴趣您可以看下AVAudioEngineOfflineRender和EZAudio

## Requirements
## Author

YUER, qiqiw124@163.com

## License

WQAudioEdit is available under the MIT license. See the LICENSE file for more info.
