#import <Cordova/CDV.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapNaviKit/AMapNaviKit.h>

@interface CDVGaode : CDVPlugin <AMapLocationManagerDelegate,AMapNaviDriveManagerDelegate,MAMapViewDelegate, AMapNaviDriveViewDelegate,AMapNaviRideManagerDelegate,AMapNaviWalkManagerDelegate,AMapNaviWalkViewDelegate,AMapNaviRideViewDelegate>{
    CLLocation *lastLocation;
    NSString *loginName;
    NSString *serverUrl;
    NSInteger interval;
    BOOL isBackgroundLocationRunning;
}
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, strong) AMapNaviDriveView *driveView;
@property (nonatomic, strong) AMapNaviWalkManager *walkManager;
@property (nonatomic, strong) AMapNaviRideManager *rideManager;
@property (nonatomic, strong) AMapNaviWalkView *walkView;
@property (nonatomic, strong) AMapNaviRideView *rideView;

- (void) startBackgroundLocate:(CDVInvokedUrlCommand*)command;
-(void)stopBackgroundLocate:(CDVInvokedUrlCommand*)command;
-(void) postToServer:(NSString *)url postData:(CLLocation *)data;
-(void) isBackgroundLocationRunning:(CDVInvokedUrlCommand*)command;
-(void) onceLocation:(CDVInvokedUrlCommand*)command;
-(void) navigation:(CDVInvokedUrlCommand*)command;
@end
