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
#import "SurfaceRecorder.h"

@interface TouchbarRecorder () <NSMachPortDelegate>
@property CGDisplayStreamRef stream;
@property dispatch_queue_t queue;
@property SurfaceRecorder *recorder;
@end

@implementation TouchbarRecorder

- (instancetype)init
{
    if (self = [super init]) {
    }
    
    return self;
}

- (void)start {
    _isRecording = YES;
    
    self.queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) ;
    dispatch_async(self.queue, ^{
        [self createDisplayStream];
    
        self.recorder = [SurfaceRecorder new];
        [self.recorder setupForSize:[DFR GetScreenSize]];
        
        if(self.stream) {
            CGDisplayStreamStart(self.stream);
        }
    });
}


- (void)createDisplayStream {
    self.stream = [DFR DisplayStreamCreate:0 queue:self.queue handler:^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef  _Nullable surface, CGDisplayStreamUpdateRef  _Nullable updateRef) {
        if(!self.isRecording) return;
        if(!surface) {
            return;
        }
        
        if(status != kCGDisplayStreamFrameStatusFrameComplete) {
            return;
        }
        

        [self.recorder recordSurface:surface at:displayTime];
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
        [self.recorder.writer finishWritingWithCompletionHandler:block];
        
        _isRecording = NO;
        while(dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)))) ;
    });
}

- (void)writeTo:(NSURL*)url {
    [[NSFileManager defaultManager] moveItemAtURL:self.recorder.outputFile toURL:url error:nil];
    [self.recorder cleanup];
}
@end
