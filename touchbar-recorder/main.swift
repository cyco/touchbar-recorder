//
//  main.swift
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 19.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

import Foundation


let output = URL(fileURLWithPath: "Movies/TouchBar Recording.mp4", isDirectory: false, relativeTo: FileManager.default.homeDirectoryForCurrentUser)
let recorder = TouchbarRecorder()

recorder.start()
while recorder.isRecording {
    RunLoop.main.run(mode: .defaultRunLoopMode, before: Date(timeIntervalSinceNow: 0.01))
}

recorder.write(to: output)
