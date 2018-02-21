//
//  TouchBarRecorder_Swift.swift
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 21.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

import Foundation
import AVFoundation

class TouchbarRecorder {
    var isRecording: Bool = false
    private var stream: CGDisplayStream?
    private var queue: DispatchQueue
    private var recorder: SurfaceRecorder
    
    init() {
        queue = DispatchQueue.global(qos: .userInitiated)
        recorder = SurfaceRecorder(size: DFRGetScreenSize())
    }
    
    public func start() {
        self.isRecording = true;
        
        self.queue.async {
            self.stream = self.createStream()
            guard self.stream != nil else { return }
            self.stream!.start()
        }
    }
    
    private func createStream() -> CGDisplayStream? {
        if let stream = SLSDFRDisplayStreamCreate(0, self.queue, { (status, time, surface, _) in
            guard self.isRecording else { return }
            guard surface != nil else { return }
            guard status == .frameComplete else { return }
            
            self.recorder.capture(surface: surface!, at: time)
        }) {
            return stream.takeUnretainedValue()
        }
        
        return nil
    }
    
    public func stop() {
        self.queue.sync {
            if let stream = self.stream {
                stream.stop()
                self.stream = nil
            }
            
            let semaphore = DispatchSemaphore(value: 0)
            self.recorder.writer.finishWriting {
                semaphore.signal()
            }
            semaphore.wait()
            
            self.isRecording = false
        }
    }
    
    public func write(to url: URL) {
        try? FileManager.default.moveItem(at: self.recorder.outputFile, to: url)
    }
}
