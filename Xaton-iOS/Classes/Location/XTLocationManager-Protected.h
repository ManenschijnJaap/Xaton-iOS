//
//  XTLocationManager-Protected.h
//  Ziggo
//
//  Created by Angel on 06/02/12.
//  Copyright (c) 2012 ZiggoBV. All rights reserved.
//


#import "XTLocationManager.h"


@class XTLocationRequest;


@interface XTLocationManager ()

@property (nonatomic, retain) NSMutableArray *requests;
@property (nonatomic, retain) CLLocationManager *locationManager;

- (void) makeRequest:(XTLocationRequest *)request;
- (void) checkForFinishedLocationRequests;
- (void) setBestLocationAccuracy;
- (void) requestTimeout:(NSTimer *)timer;

@end




@interface XTLocationRequest : NSObject {}

@property (nonatomic, assign) CLLocationAccuracy accuracy;
@property (nonatomic, assign) NSTimeInterval maxLocationAge;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, copy) XTLocationManagerCallback completionHandler;
@property (nonatomic, copy) XTLocationManagerErrorCallback errorHandler;
@property (nonatomic, retain) NSTimer *timer;

- (id)initWithAccuracy:(CLLocationAccuracy)accuracy 
        maxLocationAge:(NSTimeInterval)maxLocationAge 
               timeout:(NSTimeInterval)timeout 
     completionHandler:(XTLocationManagerCallback)completionHandler 
          errorHandler:(XTLocationManagerErrorCallback)errorHandler;

- (BOOL) isLocationValid:(CLLocation *)location;

@end