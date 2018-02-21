//
//  SurfaceRecorder.m
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 21.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

#import "SurfaceRecorder.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

@interface SurfaceRecorder ()
@property (readwrite) NSURL *outputFile;
@property (readwrite) AVAssetWriter *writer;
@property AVAssetWriterInput *videoInput;
@property AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property uint64_t startTime;
@end

@implementation SurfaceRecorder
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.outputFile = [NSURL fileURLWithPathComponents:@[NSTemporaryDirectory(), [NSUUID new].UUIDString]];
    }
    return self;
}

- (void)setupForSize:(CGSize)size {
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

- (void)recordSurface:(IOSurfaceRef)frameSurface at:(uint64_t)displayTime {
    if (self.writer.status == AVAssetWriterStatusUnknown) {
        [self.writer startWriting];
        [self.writer startSessionAtSourceTime:kCMTimeZero];
        self.startTime = displayTime;
    }
    
    if(self.writer.status == AVAssetWriterStatusFailed) {
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
    
    [self.adaptor appendPixelBuffer:pixelBuffer withPresentationTime:CMTimeMake(displayTime - self.startTime, NSEC_PER_SEC)];
    CVPixelBufferRelease(pixelBuffer);
}

- (void)cleanup {}
@end
