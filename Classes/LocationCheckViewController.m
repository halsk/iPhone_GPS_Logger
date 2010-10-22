//
//  LocationCheckViewController.m
//  FsqCheckin
//
//  Created by 関 治之 on 10/10/18.
//  Copyright 2010 Haruyuki Seki. All rights reserved.
//

#import "LocationCheckViewController.h"
#define kLBL_GPSSTART @"GPS Start"
#define kLBL_SIGSTART @"Sig Start"
#define kLBL_MAPPING @"Mapping"
#define kLBL_STOP @"Stop"
#define kLBL_SEND @"Send log"
#define kLBL_REMOVE @"Remove log"
#define kLOG_FILE @"latlong"

@implementation LocationCheckViewController

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) return nil;

	// location manager
	locMan = [[CLLocationManager alloc] init];
	locMan.delegate = self;
	[UIDevice currentDevice].batteryMonitoringEnabled = YES;
	isUpdating = NO;
	
	// mapview
	mapView = [[MKMapView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	mapView.delegate = self;
	[mapView setShowsUserLocation:YES];
	
	// set up buttons
	btnGpsStart = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btnGpsStart addTarget:self action:@selector(pressGpsStart:) forControlEvents:UIControlEventTouchUpInside];
	[btnGpsStart setTitle:kLBL_GPSSTART forState:UIControlStateNormal];
	[btnGpsStart setFrame:CGRectMake(10, 350, 100, 40)];
	btnSigStart = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btnSigStart addTarget:self action:@selector(pressSigStart:) forControlEvents:UIControlEventTouchUpInside];
	[btnSigStart setTitle:kLBL_SIGSTART forState:UIControlStateNormal];
	[btnSigStart setFrame:CGRectMake(210, 350, 100, 40)];
	btnSend = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btnSend addTarget:self action:@selector(pressSend:) forControlEvents:UIControlEventTouchUpInside];
	[btnSend setTitle:kLBL_SEND forState:UIControlStateNormal];
	[btnSend setFrame:CGRectMake(10, 400, 100, 40)];
	btnRemove = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[btnRemove addTarget:self action:@selector(pressRemove:) forControlEvents:UIControlEventTouchUpInside];
	[btnRemove setTitle:kLBL_REMOVE forState:UIControlStateNormal];
	[btnRemove setFrame:CGRectMake(210, 400, 100, 40)];
	[self.view addSubview:mapView];
	[self.view addSubview:btnGpsStart];
	[self.view addSubview:btnSigStart];
	[self.view addSubview:btnSend];
	[self.view addSubview:btnRemove];
	
    return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
// ロギング用の文字列生成
-(NSString *) makeLogText:(CLLocation *)loc{
	NSDate *now = [NSDate date]; 
	NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
	[fmt setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	 NSString *logstr = [NSString stringWithFormat:@"%@,location,%0.8f,%0.8f,%0.0f,%0.0f,%0.2f",
						 [fmt stringFromDate:now],
						loc.coordinate.latitude,
						loc.coordinate.longitude,
						loc.altitude,
						loc.horizontalAccuracy,
						 [[UIDevice currentDevice] batteryLevel]
						];
	return logstr;
}
// 与えられたファイル名をDocumentフォルダ内での完全なファイル名に変換
- (NSString *)getDocumentPath:(NSString *)file
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:file];
}
// タイムスタンプつきのログ
-(void) logTextWithTime:(NSString *)log{
	NSDate *now = [NSDate date]; 
	NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
	[fmt setDateFormat:@"yyyy/MM/dd HH:mm:ss"];
	[self logText:[NSString stringWithFormat:@"%@,%@", [fmt stringFromDate:now], log]];
}
/*
 * ログ
 */
-(void) logText:(NSString *)log{
	NSError *error = nil;
	NSString *fullPath = [self getDocumentPath:kLOG_FILE];
	NSFileManager *filem = [NSFileManager defaultManager];
	NSString *text;
	if ([filem fileExistsAtPath:fullPath]){
		text = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
	}else{
		text = @"";
	}
	NSString *data = [text stringByAppendingFormat:@"%@\n", log];
	[data writeToFile:fullPath atomically:NO encoding:NSUTF8StringEncoding error:&error];
	if (error){
		TRACE(@"write error:%@", [error localizedDescription]);
	}
	TRACE(@"%@", log);
}
// ログファイル削除
-(void) removeLogFile{
	NSString *fullPath = [self getDocumentPath:kLOG_FILE];
	NSFileManager *filem = [NSFileManager defaultManager];
	NSError *error = nil;
	[filem removeItemAtPath:fullPath error:&error];
}
// ログをメール送信
-(void) sendLog{
	NSString *text = [self readLog];
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto:seki@cirius.co.jp?body=%@", 
																	 [text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
}
-(NSString *)readLog{
	NSString *fullPath = [self getDocumentPath:kLOG_FILE];
	NSError *error = nil;
	return [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
}

-(void)startSigLog{
	if (isUpdating){
		[self logText:@"stop logging"];
		[locMan stopMonitoringSignificantLocationChanges];
		isUpdating = NO;
		[btnSigStart setTitle:kLBL_SIGSTART forState:UIControlStateNormal];
	}else{
		[self logText:@"start logging"];
		[locMan startMonitoringSignificantLocationChanges];
		isUpdating = YES;
		[btnSigStart setTitle:kLBL_STOP forState:UIControlStateNormal];
	}
}
-(void)startGpsLog{
	if (isUpdating){
		[self logText:@"stop logging"];
		[locMan stopUpdatingLocation];
		isUpdating = NO;
		[btnGpsStart setTitle:kLBL_GPSSTART forState:UIControlStateNormal];
	}else{
		[self logText:@"start logging"];
		[locMan startUpdatingLocation];
		isUpdating = YES;
		[btnGpsStart setTitle:kLBL_STOP forState:UIControlStateNormal];
	}
}

#pragma mark --
#pragma mark Buttons
-(void)pressSigStart:(UIButton *)sender{
	[self startSigLog];
}
-(void)pressGpsStart:(UIButton *)sender{
	[self startGpsLog];
}
-(void)pressSend:(UIButton *)sender{
	[self sendLog];
}
-(void)pressRemove:(UIButton *)sender{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"confirmation" message:@"are you sure to delete log file?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}
#pragma mark --
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 1){
		[self removeLogFile];
	}
}

#pragma mark --
#pragma mark CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
	didUpdateToLocation:(CLLocation *)newLocation
		   fromLocation:(CLLocation *)oldLocation{
	NSString *log = [self makeLogText:newLocation];
	[mapView setCenterCoordinate:newLocation.coordinate];
	[self logText:log];
}
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	[self logTextWithTime:[NSString stringWithFormat:@"LocationManager Failed %@", [error localizedDescription]]];
}
#pragma mark --
#pragma mark MKMapViewDelegate
-(MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)anAnnotation {
	return nil;
}

-(void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated{
}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
}

-(void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)userLocation{
}

#pragma mark --
- (void)dealloc {
	[mapView release];
	[locMan release];
	[btnGpsStart release];
	[btnSigStart release];
	[btnSend release];
	[btnRemove release];
    [super dealloc];
}


@end
