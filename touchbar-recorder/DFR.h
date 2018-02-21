//
//  DFR.h
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 19.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFR : NSObject
+ (CGDisplayStreamRef _Nullable )DisplayStreamCreate:(int)displayID queue:(dispatch_queue_t _Nullable)queue handler: (CGDisplayStreamFrameAvailableHandler _Nullable )handler;
+ (CGSize)GetScreenSize;
@end
