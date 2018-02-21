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

signal(SIGINT) { _ in
    if recorder.isRecording {
        recorder.stop()
        print("\u{0008}\u{0008}", terminator: "")
        print("Saving video...")
        recorder.write(to: output)
        print("All done. The video is at \(output)")
    }
}

recorder.start()

sigsuspend(nil)
