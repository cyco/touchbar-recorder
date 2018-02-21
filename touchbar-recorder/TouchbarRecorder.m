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

- (instancetype)init
{
    if (self = [super init]) {
        self.outputFile = [NSURL fileURLWithPathComponents:@[NSTemporaryDirectory(), [NSUUID new].UUIDString]];
    }
    
    return self;
}

- (void)start {
    _isRecording = YES;
    
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) ;
    dispatch_async(self.queue, ^{
        [self setupAssetWriter];
        [self createDisplayStream];
        
        if(self.stream) {
            CGDisplayStreamStart(self.stream);
        }
    });
}

- (void)setupAssetWriter {
    CGSize size = [DFR GetScreenSize];
    self.writer = [AVAssetWriter assetWriterWithURL:self.outputFile fileType:AVFileTypeMPEG4 error:nil];
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:
                       @{
                         AVVideoCodecKey: AVVideoCodecTypeH264,
                         AVVideoWidthKey: @(size.width * 2),
                         AVVideoHeightKey: @(size.height  * 2),
                         AVVideoCompressionPropertiesKey: @{
                                 AVVideoMaxKeyFrameIntervalKey: @(60)
                                 }
                         }];
    self.videoInput.expectsMediaDataInRealTime = YES;
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:@{}];
    [self.writer addInput:self.videoInput];
}

- (void)createDisplayStream {
    __block uint64_t start;
    self.stream = [DFR DisplayStreamCreate:0 queue:self.queue handler:^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef  _Nullable frameSurface, CGDisplayStreamUpdateRef  _Nullable updateRef) {
        if(!self.isRecording) return;
        
        if (self.writer.status == AVAssetWriterStatusUnknown) {
            [self.writer startWriting];
            [self.writer startSessionAtSourceTime:kCMTimeZero];
            start = displayTime;
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
            usleep(100);
        }
        
        [self.adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(displayTime - start, NSEC_PER_SEC)];
        CVPixelBufferRelease(pixelBuffer);
    }];
}

- (void)stop {
    dispatch_sync(self.queue, ^{
        if(self.stream) {
            CGDisplayStreamStop(self.stream);
            self.stream = NULL;
        }
        
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        dispatch_block_t block = ^{
            dispatch_semaphore_signal(sem);
        };
        [self.writer finishWritingWithCompletionHandler:block];
        
        _isRecording = NO;
        while(dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)))) ;
    });
}

- (void)writeTo:(NSURL*)url {
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    if([[NSFileManager defaultManager] moveItemAtURL:self.outputFile toURL:url error:nil]) {
        self.outputFile = nil;
    }
    
    [self cleanup];
}

- (void)cleanup {
    if(self.outputFile) {
        [[NSFileManager defaultManager] removeItemAtURL:self.outputFile error:nil];
    }
}
@end
