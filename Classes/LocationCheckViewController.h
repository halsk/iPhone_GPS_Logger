//
//  LocationCheckViewController.h
//  FsqCheckin
//
//  Created by 関 治之 on 10/10/18.
//  Copyright 2010 Haruyuki Seki. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface LocationCheckViewController : UIViewController<MKMapViewDelegate,CLLocationManagerDelegate,UIAlertViewDelegate,MKMapViewDelegate> {
	MKMapView *mapView;
	UIButton *btnGpsStart;
	UIButton *btnSigStart;
	UIButton *btnSend;
	UIButton *btnRemove;
	CLLocationManager *locMan;
	BOOL isUpdating;
}
-(void)startSigLog;
-(void)startGpsLog;
-(NSString *) makeLogText:(CLLocation *)loc;
- (NSString *)getDocumentPath:(NSString *)file;
-(void) logText:(NSString *)log;
-(void) logTextWithTime:(NSString *)log;
-(void) removeLogFile;
-(void) sendLog;
-(NSString *)readLog;
	
@end
