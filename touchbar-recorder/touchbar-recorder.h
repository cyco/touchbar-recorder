#import <CoreGraphics/CoreGraphics.h>

CGDisplayStreamRef SLSDFRDisplayStreamCreate(int displayID, dispatch_queue_t queue, CGDisplayStreamFrameAvailableHandler handler);
CGSize DFRGetScreenSize(void);
