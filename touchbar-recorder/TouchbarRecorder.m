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
        NSLog(@"callback");
        if(!self.isRecording) return;
        
        if (self.writer.status == AVAssetWriterStatusUnknown) {
            NSLog(@"unknonw status");

            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:kCMTimeZero];
        }
        
        if(self.writer.status == AVAssetWriterStatusFailed) {
            NSLog(@"status is failed");
            return;
        }
        
        if(!frameSurface) {
            NSLog(@"no surface");
            return;
        }
        if(status != kCGDisplayStreamFrameStatusFrameComplete) {
         
            NSLog(@"not a complete frame");
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
            NSLog(@"Could not create pixel buffer");
            return;
        }
        
        while(!_adaptor.assetWriterInput.isReadyForMoreMediaData) {
            NSLog(@"waiting for asset writer");
            CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true);
        }
        
        [self.adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(frames++, 60)];
        CVPixelBufferRelease(pixelBuffer);
        
        if(frames > 30) {
            NSLog(@"stopping on main");
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
    NSLog(@"stopping");
    if(self.stream) {
        CGDisplayStreamStop(self.stream);
        self.stream = NULL;
    }
    
    __block BOOL finishedWriting = NO;
    [self.writer finishWritingWithCompletionHandler:^{
        finishedWriting = YES;
        NSLog(@"finished writing");
    }];
    
    while(!finishedWriting) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true);
    }
    
    _isRecording = NO;
    NSLog(@"stopped");
}

- (void)writeTo:(NSURL*)url {
    NSLog(@"writeTo");
    NSError *error = nil;
    [[NSFileManager defaultManager] moveItemAtURL:self.outputFile toURL:url error:&error];
    NSLog(@"%@", error);
}
@end
