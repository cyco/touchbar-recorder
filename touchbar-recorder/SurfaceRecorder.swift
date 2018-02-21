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

class SurfaceRecorder {
    let outputFile = URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(UUID().uuidString)")
    var writer: AVAssetWriter
    var videoInput: AVAssetWriterInput
    var adaptor: AVAssetWriterInputPixelBufferAdaptor
    private var startTime: UInt64 = 0

    init(size: CGSize) {
        self.writer = try! AVAssetWriter(url: outputFile, fileType: .mp4)
        self.videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width * 2,
            AVVideoHeightKey: size.height * 2,
            AVVideoCompressionPropertiesKey: [
                AVVideoMaxKeyFrameIntervalKey: 60,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264High41
            ],
            ])
        self.videoInput.expectsMediaDataInRealTime = true
        self.adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.videoInput, sourcePixelBufferAttributes: [:])
        self.writer.add(self.videoInput)
    }
    
    public func capture(surface: IOSurfaceRef, at time: UInt64) {
        if self.writer.status == .unknown {
            self.writer.startWriting()
            self.writer.startSession(atSourceTime: kCMTimeZero)
            self.startTime = time
        }
    
        guard self.writer.status != .failed else { return }
        
        let attributes = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
        ]
        var unmanagedBuffer: Unmanaged<CVPixelBuffer>? = nil
        _ = CVPixelBufferCreateWithIOSurface(nil, surface, attributes as CFDictionary, &unmanagedBuffer)
        
        while !self.adaptor.assetWriterInput.isReadyForMoreMediaData {
            usleep(100)
        }
        
        let now = time - startTime
        self.adaptor.append(unmanagedBuffer!.takeUnretainedValue(), withPresentationTime: CMTimeMake(Int64(now), Int32(NSEC_PER_SEC)))
    }
}
