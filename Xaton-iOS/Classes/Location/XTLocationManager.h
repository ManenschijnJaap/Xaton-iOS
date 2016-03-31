//
//  XTLocationManager.h
//  Ziggo
//
//  Created by Angel on 06/02/12.
//  Copyright (c) 2012 ZiggoBV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kXTLocationManagerLoggingEnabled (0)

typedef void (^XTLocationManagerCallback)(CLLocation *);
typedef void (^XTLocationManagerErrorCallback)(NSError *);


@interface XTLocationManager : NSObject <CLLocationManagerDelegate>

//Last cached location
@property (nonatomic, readonly) CLLocation *lastLocation;


//Shared object of the Singleton
+ (XTLocationManager *)mainLocationManager;

//Request new location
- (void) makeRequestWithAccuracy:(CLLocationAccuracy)accuracy
                  maxLocationAge:(NSTimeInterval)maxLocationAge
                         timeout:(NSTimeInterval)timeout
               completionHandler:(XTLocationManagerCallback)completionHandler
                    errorHandler:(XTLocationManagerErrorCallback)errorHandler;

@end