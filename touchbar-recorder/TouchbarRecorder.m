//
//  TouchbarRecorder.m
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 20.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

#import "TouchbarRecorder.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import "DFR.h"

@interface TouchbarRecorder () <NSMachPortDelegate>
@property NSURL *outputFile;
@property AVAssetWriter *writer;
@property AVAssetWriterInput *videoInput;
@property AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property CGDisplayStreamRef stream;
@property dispatch_queue_t queue;
@end

@implementation TouchbarRecorder
- (void)start {
    _isRecording = YES;
    CGSize size = [DFR GetScreenSize];
    self.outputFile = [NSURL fileURLWithPathComponents:@[NSTemporaryDirectory(), [NSUUID new].UUIDString]];
    
    self.writer = [AVAssetWriter assetWriterWithURL:self.outputFile fileType:AVFileTypeMPEG4 error:nil];
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:
                       @{
                         AVVideoCodecKey: AVVideoCodecTypeH264,
                         AVVideoWidthKey: @(size.width * 2),
                         AVVideoHeightKey: @(size.height  * 2)
                         }];
    self.videoInput.expectsMediaDataInRealTime = YES;
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:@{
                                                                                                                                                              
                                                                                                                                                              }];
    [self.writer addInput:self.videoInput];
    __block NSInteger frames = 0;
    
    self.stream = [DFR DisplayStreamCreate:0 queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) handler:^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef  _Nullable frameSurface, CGDisplayStreamUpdateRef  _Nullable updateRef) {
        if(!self.isRecording) return;
        
        if (self.writer.status == AVAssetWriterStatusUnknown) {
            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:kCMTimeZero];
        }
        
        if(self.writer.status == AVAssetWriterStatusFailed) {
            return;
        }
        
        if(!frameSurface) {
            return;
        }
        if(status != kCGDisplayStreamFrameStatusFrameComplete) {
            return;
        }
        
        CVPixelBufferRef pixelBuffer;
        CVReturn ret;
        NSDictionary *pixelBufferAttributes = @{
                                                (NSString*)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)
                                                };
        
        ret = CVPixelBufferCreateWithIOSurface(nil, frameSurface, (__bridge CFDictionaryRef _Nullable)(pixelBufferAttributes), &pixelBuffer);
        CVPixelBufferRetain(pixelBuffer);
        
        if(ret != kCVReturnSuccess) {
            return;
        }
        
        while(!_adaptor.assetWriterInput.isReadyForMoreMediaData) {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true);
        }
        
        [self.adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(frames++, 60)];
        CVPixelBufferRelease(pixelBuffer);
        
        if(frames > 30) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self stop];
            });
        }
    }];
    
    if(self.stream) {
        CGDisplayStreamStart(self.stream);
    }
}

- (void)stop {
    if(self.stream) {
        CGDisplayStreamStop(self.stream);
        self.stream = NULL;
    }
    
    __block BOOL finishedWriting = NO;
    [self.writer finishWritingWithCompletionHandler:^{
        finishedWriting = YES;
    }];
    
    while(!finishedWriting) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true);
    }
    
    _isRecording = NO;
}

- (void)writeTo:(NSURL*)url {
    [[NSFileManager defaultManager] moveItemAtURL:self.outputFile toURL:url error:nil];
}
@end
