//
//  DFR.m
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 19.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

#import "DFR.h"
#import <Cocoa/Cocoa.h>
#import <CoreGraphics/CoreGraphics.h>

CGDisplayStreamRef SLSDFRDisplayStreamCreate(int displayID, dispatch_queue_t queue, CGDisplayStreamFrameAvailableHandler handler);
CGSize DFRGetScreenSize(void);

@implementation DFR
+ (CGDisplayStreamRef)DisplayStreamCreate:(int)displayID queue:(dispatch_queue_t)queue handler: (CGDisplayStreamFrameAvailableHandler)handler {
    return SLSDFRDisplayStreamCreate(displayID, queue, handler);
}

+ (CGSize)GetScreenSize {
    return DFRGetScreenSize();
}

@end
