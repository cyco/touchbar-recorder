//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#import <CoreGraphics/CoreGraphics.h>

CGDisplayStreamRef SLSDFRDisplayStreamCreate(int displayID, dispatch_queue_t queue, CGDisplayStreamFrameAvailableHandler handler);
CGSize DFRGetScreenSize(void);

