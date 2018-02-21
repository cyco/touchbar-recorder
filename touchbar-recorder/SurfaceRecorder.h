//
//  SurfaceRecorder.h
//  touchbar-recorder
//
//  Created by Christoph Leimbrock on 21.02.18.
//  Copyright © 2018 Christoph Leimbrock. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVAssetWriter;
@interface SurfaceRecorder : NSObject
- (void)setupForSize:(CGSize)size;
- (void)recordSurface:(IOSurfaceRef)frameSurface at:(uint64_t)displayTime;
- (void)cleanup;
@property (readonly) AVAssetWriter *writer;
@property (readonly) NSURL *outputFile;
@end
