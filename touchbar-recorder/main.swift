/*
 Copyright 2018 Christoph Leimbrock
 
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the
 "Software"), to deal in the Software without restriction, including
 without limitation the rights to use, copy, modify, merge, publish,
 distribute, sublicense, and/or sell copies of the Software, and to
 permit persons to whom the Software is furnished to do so, subject to
 the following conditions:
 
 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

let basename = "TouchBar Recording"
let fileExtension = "mp4"
let output = URL(fileURLWithPath: "Movies/.mp4", isDirectory: false, relativeTo: FileManager.default.homeDirectoryForCurrentUser)

func printUsage(code: Int32 = 0) {
    print("Usage: touchbar-recorder [<options>]")
    print("       When called without any arguments, a video of your touchbar is recorded until you press ctrl-c.")
    print("       Output is saved to ~/Movies")
    print("")
    print("Options:")
    print("    --help     Show this message")
    print("    --version  Print version and exit")
    print()
    exit(code)
}

for option in CommandLine.arguments.dropFirst() {
    switch option {
    case "--help": fallthrough
    case "-help": fallthrough
    case "-h": fallthrough
    case "-?": printUsage()
    case "--version":
        print("touchbar-reporter version 0.1")
        exit(0)
    default:
        print("Unknown option: \(option)")
        printUsage(code: 1)
    }
}

print("Recording your touchbar… Hit ctrl-c to stop.")

let recorder = TouchbarRecorder()

signal(SIGINT) { _ in
    if recorder.isRecording {
        recorder.stop()
        print("\u{0008}\u{0008}", terminator: "")
        print("Saving video…")

        let outputName = FileNameGenerator(basename: basename, fileExtension: fileExtension, directory: output).outputName
        recorder.write(to: URL(fileURLWithPath: outputName, relativeTo: output))
        print("All done.")
        print("The recording is at ~/Movies/\(outputName)")
    }
}

recorder.start()

sigsuspend(nil)
