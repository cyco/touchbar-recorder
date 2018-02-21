//
//  main.swift
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 19.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

import Foundation

let basename = "TouchBar Recording"
let fileExtension = "mp4"
let output = URL(fileURLWithPath: "Movies/.mp4", isDirectory: false, relativeTo: FileManager.default.homeDirectoryForCurrentUser)

let recorder = TouchbarRecorder()

signal(SIGINT) { _ in
    if recorder.isRecording {
        recorder.stop()
        print("\u{0008}\u{0008}", terminator: "")
        print("Saving video...")

        let outputName = FileNameGenerator(basename: basename, fileExtension: fileExtension, directory: output).outputName
        recorder.write(to: URL(fileURLWithPath: outputName, relativeTo: output))
        print("All done. The video is at ~/Movies/\(outputName)")
    }
}

recorder.start()

sigsuspend(nil)
