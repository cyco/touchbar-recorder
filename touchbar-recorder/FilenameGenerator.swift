//
//  FilenameGenerator.swift
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 21.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

import Foundation

class FileNameGenerator {
    let basename: String
    let fileExtension: String
    let directory: URL
    
    init(basename: String, fileExtension: String, directory: URL) {
        self.basename = basename
        self.fileExtension = fileExtension
        self.directory = directory
    }
    
    lazy var outputName: String = {
        var result: String = "\(self.basename).\(self.fileExtension)"
        var iteration = 0
        
        while (try? URL(fileURLWithPath: result, relativeTo: self.directory).checkResourceIsReachable()) ?? false {
            iteration += 1
            result = "\(self.basename) \(iteration).\(self.fileExtension)"
        }
        
        return result
    }()
}
