//
//  GeoLogAppDelegate.h
//  GeoLog
//
//  Created by 関 治之 on 10/10/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationCheckViewController.h"

@interface GeoLogAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	LocationCheckViewController *locController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

