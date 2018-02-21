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
            
            while self.recorder.writer.status == AVAssetWriterStatus.unknown {
                usleep(100)
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
