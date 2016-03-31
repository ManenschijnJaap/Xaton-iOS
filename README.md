## External libraries not included in Xaton-IOS
* [XTRestLayer](https://github.com/Xaton/XTRestLayer)

## Using libraries
* Use `cocoapods` http://cocoapods.org
* Check https://gist.github.com/xslim/5531980


Example:

``` ruby
pod 'XTSettings', podspec: 'https://gist.github.com/xslim/5531980/raw/f80b4126635995ad27f357e4784c0bab61afa8f3/XTSettings.podspec'
```

## XTCaptiveNetwork

Example usage

``` ruby
pod 'SVProgressHUD'
pod 'XTCaptiveNetwork', podspec: 'https://gist.github.com/xslim/5531980/raw/c11508bad5cfd0f7589863b7b3af9392f692f330/XTCaptiveNetwork.podspec'

```


``` obj-c
#import "XTCaptiveNetwork.h"
#import "IJContext.h"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
// code before
[self configureCaptiveNetwork]
// code after
}

#pragma mark - Captive Network

- (void)configureCaptiveNetwork {
    XTCaptiveNetwork *cn = [XTCaptiveNetwork injectiveInstantiate];
    cn.showDefaultHUDs = YES;
    [cn startMonitoringSSIDs:@[@"SuperDirect", @"SuperDirect1", @"SuperDirect2"]];
    [self updateCaptiveNetworkCredentials];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCaptiveNetworkCredentials) name:kLoginStateChangedNotification object:nil];
}

- (void)updateCaptiveNetworkCredentials {
    SDUser *user = [[SDLoginManager injectiveInstantiate] loggedUser];
    if (user.isAnonymous) {
        [[XTCaptiveNetwork injectiveInstantiate] setCredentials:nil];
    } else {
        [[XTCaptiveNetwork injectiveInstantiate] setCredentials:@{
         @"username": @"authorization_header64",
         @"password": [SDNetworkConnection calculatedAuthHeaderInBase64],
         @"api_url": [SDNetworkConnection apiUrl]}];
    }
}

```


## XTPerimeter


Example usage

``` ruby
pod 'XTPerimeter', podspec: 'https://gist.github.com/xslim/5531980/raw/dea4de63743a38f3ab995a2aa6db6bfae61ac43b/XTPerimeter.podspec'
```

``` obj-c
#pragma mark - XTPerimeter

- (void)setupPerimeter {
    XTPerimeter *perimeter = [XTPerimeter injectiveInstantiate];
    perimeter.didEnterRegionBlock = ^(CLRegion *region) {
        BOOL appActive = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
        NSString *identifier = region.identifier;
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"You are approaching %@! Prepare your order?", nil), identifier];
        
        if (appActive) {
            [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        } else {
            UILocalNotification *notification = [[UILocalNotification alloc] init];
            notification.alertBody = message;
            notification.alertAction = @"OK";
            notification.hasAction = YES;
            notification.soundName = UILocalNotificationDefaultSoundName;
            notification.applicationIconBadgeNumber = 0;
            notification.userInfo = @{@"location": identifier};
            [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
        }
    };
        
    perimeter.launchedOnRegionBlock = ^(CLRegion *region) {
        NSString *identifier = region.identifier;
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"You are approaching %@! Prepare your order?", nil), identifier];
        
        [[[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    };
    
    perimeter.didExitRegionBlock = ^(CLRegion *region) {
        BOOL appActive = ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive);
        if (appActive) {
            NSString *message = [NSString stringWithFormat:@"Exited: %@", region.identifier];
            [SVProgressHUD showErrorWithStatus:message];
            [SVProgressHUD dismiss];
        }
    };
    
    //[perimeter addCoordinateForMonitoring:CLLocationCoordinate2DMake(52.336057, 4.886920) identifier:@"Xaton" withRadius:200];
}


// Use it like
- (void)geofencePickupPoint:(SDPickupPoint *)point {
  XTPerimeter *perimeter = [XTPerimeter injectiveInstantiate];
  [perimeter addCoordinateForMonitoring:point.coordinate identifier:point.name];
}

```


## XTModel

XTModel is a wrapper to unify access to model objects no matter if they are stored as a CoreData entity or in memory.

Example usage

``` ruby
pod 'XTModel', :podspec => 'https://gist.github.com/angelolloqui/5575942/raw/c0ce815eb73302758b31a41bef1ea5f0c8c6a423/XTModel.podspec'
```

For memory objects an NSCache is used. Declared them as:

``` obj-c
@interface SDAddress : XTModelVolatileObject
//Properties
@end
```

For core data objects just use regular declaration:
``` obj-c
@interface SDAddress : NSManagedObject
//Properties
@end
```

Then, use them as:
``` obj-c
//Read or create if none exists
SDAddress *address = [SDAddress objectWithIdentifier:identifier];

//Get many objects following one predicate
NSArray *allAddresses = [SDAddress objectsWithPredicate:nil sortedBy:nil];

//Delete an object
[address deleteObject];
```

Note that NSManagedObjectContexts are not persisted, so when a set of changes are done you may require to call:

``` obj-c
[[NSManagedObjectContext contextForCurrentThread] saveToPersistentStoreAndWait];
```




## Other Xaton-iOS helpers and components

Xaton-iOS contains some other utilities that can be imported separately or by the use of CocoaPods.

Example usage of all other components

``` ruby
pod 'Xaton-iOS', podspec: 'https://gist.github.com/angelolloqui/7560850/raw/4947623d2b7a5f2931af0088e235422ee81a5206/Xaton-iOS.podspec'
```

or for some subspecs:
``` ruby
pod 'Xaton-iOS/UI', podspec: 'https://gist.github.com/angelolloqui/7560850/raw/4947623d2b7a5f2931af0088e235422ee81a5206/Xaton-iOS.podspec'
pod 'Xaton-iOS/Utils', podspec: 'https://gist.github.com/angelolloqui/7560850/raw/4947623d2b7a5f2931af0088e235422ee81a5206/Xaton-iOS.podspec'
pod 'Xaton-iOS/Location', podspec: 'https://gist.github.com/angelolloqui/7560850/raw/4947623d2b7a5f2931af0088e235422ee81a5206/Xaton-iOS.podspec'
```
