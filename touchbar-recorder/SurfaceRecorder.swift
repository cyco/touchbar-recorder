//
//  SurfaceRecorder.swift
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 21.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

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
            AVVideoHeightKey: size.height  * 2,
            AVVideoCompressionPropertiesKey: [
                AVVideoMaxKeyFrameIntervalKey: 60
            ]
            ])
        self.videoInput.expectsMediaDataInRealTime = false
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
        print(Int64(now) == now, NSEC_PER_SEC == Int32(NSEC_PER_SEC))
        self.adaptor.append(unmanagedBuffer!.takeUnretainedValue(), withPresentationTime: CMTimeMake(Int64(now), Int32(NSEC_PER_SEC)))
    }
}
