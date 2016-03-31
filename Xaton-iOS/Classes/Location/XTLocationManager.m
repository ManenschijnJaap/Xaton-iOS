//
//  XTLocationManager.m
//  Ziggo
//
//  Created by Angel on 06/02/12.
//  Copyright (c) 2012 ZiggoBV. All rights reserved.
//

#import "XTLocationManager.h"
#import "XTLocationManager-Protected.h"
#import <MapKit/MapKit.h>
#import <objc/runtime.h>

static XTLocationManager *mainLocationManager = nil;

@interface MKUserLocation (XTLocationManager)
+ (void)setupLocationChange;
@end

@implementation XTLocationManager

@synthesize requests = requests_;
@synthesize locationManager = locationManager_;

#pragma mark - Singleton implementation

+ (XTLocationManager *)mainLocationManager {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        mainLocationManager = [[self alloc] init];
    });
    return mainLocationManager;
}

- (void)dealloc {
    NSAssert(NO, @"You should not dealloc the DataManager");
    [super dealloc];
}

- (id) init {
    self = [super init];
    
    if (self) {
        //Setup the request array
        self.requests = [NSMutableArray array];
        
        // Setup the location manager
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        self.locationManager = locationManager;
        [locationManager release];
        
        //Setup MKUser
        [MKUserLocation setupLocationChange];
    }
    
    return self;
}

#pragma mark - Public methods

- (void) makeRequestWithAccuracy:(CLLocationAccuracy)accuracy maxLocationAge:(NSTimeInterval)maxLocationAge timeout:(NSTimeInterval)timeout completionHandler:(XTLocationManagerCallback)completionHandler errorHandler:(XTLocationManagerErrorCallback)errorHandler {
    XTLocationRequest *req = [[XTLocationRequest alloc] initWithAccuracy:accuracy
                                                          maxLocationAge:maxLocationAge
                                                                 timeout:timeout
                                                       completionHandler:completionHandler
                                                            errorHandler:errorHandler];
    
    [self makeRequest:req];
    [req release];
}

#pragma mark - Private methods

- (CLLocation *)lastLocation {
    return self.locationManager.location;
}

- (void) makeRequest:(XTLocationRequest *)request {
    //Check the request with the last loaded location
    if ([request isLocationValid:self.lastLocation]) {
        if (request.completionHandler) {
            request.completionHandler(self.lastLocation);
        }
        return;
    }
    
    @synchronized (self) {
        //Add the timer to handle timeouts
        if (request.timeout > 0) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                request.timer=[NSTimer scheduledTimerWithTimeInterval:request.timeout target:self selector:@selector(requestTimeout:) userInfo:request repeats:NO];
            });
        }
        
        //Add the request to the array
        [self.requests addObject:request];
        
        //Reset the location accuracy based on the new requests
        [self setBestLocationAccuracy];
        
#ifdef __IPHONE_8_0
        CLAuthorizationStatus code = [CLLocationManager authorizationStatus];
        if (code == kCLAuthorizationStatusNotDetermined && ([locationManager_ respondsToSelector:@selector(requestAlwaysAuthorization)] || [locationManager_ respondsToSelector:@selector(requestWhenInUseAuthorization)])) {
            // choose one request according to your business.
            if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"]){
                [locationManager_ requestAlwaysAuthorization];
            } else if([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"]) {
                [locationManager_ requestWhenInUseAuthorization];
            } else {
                NSLog(@"Info.plist does not contain NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription");
            }
        }
#endif
        //Start updating location
        [locationManager_ startUpdatingLocation];
    }
}

- (void) checkForFinishedLocationRequests {
    NSMutableArray *finishedReqs = [NSMutableArray array];
    
    @synchronized(self) {
        //Check each remaining location with the new data
        for (XTLocationRequest *req in requests_) {
            //If the location is valid for the request, add it to finished and notify
            if ([req isLocationValid:self.lastLocation]) {
                [finishedReqs addObject:req];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [req.timer invalidate];
                    if (req.completionHandler) {
                        req.completionHandler(self.lastLocation);
                    }
                });
            }
        }
        
        //Remove finished requests
        [self.requests removeObjectsInArray:finishedReqs];
        
        //Stop locating if no request remaining
        if ([self.requests count] <= 0)
            [self.locationManager stopUpdatingLocation];
    }
}

- (void) setBestLocationAccuracy {
    //Set the most precise accuracy in the locationManager
    CLLocationAccuracy bestAcc = kCLLocationAccuracyThreeKilometers;
    
    for (XTLocationRequest *req in requests_) {
        if (req.accuracy < bestAcc)
            bestAcc = req.accuracy;
    }
    
    self.locationManager.desiredAccuracy = bestAcc;
}

- (void) requestTimeout:(NSTimer *)timer {
    XTLocationRequest *req = (XTLocationRequest *)[timer userInfo];
    
    @synchronized(self) {
        if ([requests_ containsObject:req]) {
#if kXTLocationManagerLoggingEnabled
            NSLog(@"[XTLocationManager] Location timeout. Last location received with accuracy %f and needed %f", self.lastLocation.horizontalAccuracy, req.accuracy);
#endif
            //Notify the delegate
            if (req.errorHandler) {
                req.errorHandler(nil);
            }
            
            //Remove the request
            [requests_ removeObject:req];
            
            if ([requests_ count] <= 0)
                [self.locationManager stopUpdatingLocation];
        }
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
#if kXTLocationManagerLoggingEnabled
    NSLog(@"[XTLocationManager] New Location found at %f %f with accuracy %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy);
#endif
    
    [mainLocationManager willChangeValueForKey:@"lastLocation"];
    
    //Check finished requests
    [self checkForFinishedLocationRequests];
    
    [mainLocationManager didChangeValueForKey:@"lastLocation"];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
#if kXTLocationManagerLoggingEnabled
    for (CLLocation *newLocation in locations) {
        NSLog(@"[XTLocationManager] New Location found at %f %f with accuracy %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy);
    }
#endif
    
    [mainLocationManager willChangeValueForKey:@"lastLocation"];
    
    //Check finished requests
    [self checkForFinishedLocationRequests];
    
    [mainLocationManager didChangeValueForKey:@"lastLocation"];
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
#if kXTLocationManagerLoggingEnabled
    NSLog(@"[XTLocationManager] Error finding location: %@", [error description]);
#endif
    
    //Stop updating and notify requests
    @synchronized(self) {
        [self.locationManager stopUpdatingLocation];
        
        for (XTLocationRequest *req in requests_) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [req.timer invalidate];
                if (req.errorHandler) {
                    req.errorHandler(error);
                }
            });
        }
        
        [requests_ removeAllObjects];
    }
}

@end



@implementation XTLocationRequest

@synthesize accuracy = accuracy_, maxLocationAge = maxLocationAge_, timeout = timeout_, completionHandler = completionHandler_, errorHandler = errorHandler_, timer = timer_;

- (void) dealloc {
    self.completionHandler = nil;
    self.errorHandler = nil;
    [self.timer invalidate];
    self.timer = nil;
    
    [super dealloc];
}

- (id)initWithAccuracy:(CLLocationAccuracy)accuracy
        maxLocationAge:(NSTimeInterval)maxLocationAge
               timeout:(NSTimeInterval)timeout
     completionHandler:(XTLocationManagerCallback)completionHandler
          errorHandler:(XTLocationManagerErrorCallback)errorHandler {
    self = [super init];
    
    if (self) {
        self.accuracy = accuracy;
        self.maxLocationAge = maxLocationAge;
        self.timeout = timeout;
        self.completionHandler = completionHandler;
        self.errorHandler = errorHandler;
    }
    
    return self;
}

- (BOOL) isLocationValid:(CLLocation *)location {
    if (!location) return NO;
    
    //Check the accuaracy
    if (self.accuracy > 0 && location.horizontalAccuracy > self.accuracy) {
        return NO;
    }
    
    //Check the age
    if (self.maxLocationAge > 0 && -[location.timestamp timeIntervalSinceNow] > self.maxLocationAge) {
        return NO;
    }
    
    return YES;
}

@end


// MKUserLocation method swizzling to detect location changes in maps and fire the KVO of the location
@implementation MKUserLocation (XTLocationManager)

+ (void)setupLocationChange {
    //Swizzle methods to track viewDidLoad actions
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method setLocationOriginal = class_getInstanceMethod([MKUserLocation class], @selector(setLocation:));
        Method setLocationCustom = class_getInstanceMethod([MKUserLocation class], @selector(setLocationCustom:));
        method_exchangeImplementations(setLocationOriginal, setLocationCustom);
    });
}

- (void)setLocationCustom:(CLLocation *)location {
    [mainLocationManager willChangeValueForKey:@"lastLocation"];
    [self setLocationCustom:location];
    [mainLocationManager didChangeValueForKey:@"lastLocation"];
}

@end


