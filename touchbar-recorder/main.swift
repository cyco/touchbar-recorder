//
//  main.swift
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 19.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

import Foundation

var outputPath = "~/Movies/Touchbar Recording.mp4"

print("Recording your touchbar... Hit ctrl-c to stop.")

signal(SIGINT) { _ in
    print("\u{0008}\u{0008}", terminator: "")
    print("Saving video...")
    print("All done. The video is at \(outputPath)")
}
sigsuspend(nil)

