//
//  TouchbarRecorder.h
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 20.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TouchbarRecorder : NSObject
- (void)start;
- (void)stop;
- (void)writeTo:(NSURL*)url;
@property BOOL isRecording;
@end
