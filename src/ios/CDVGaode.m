/********* gaode.m Cordova Plugin Implementation *******/

#import "CDVGaode.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import "SpeechSynthesizer.h"

@implementation CDVGaode

- (void)pluginInitialize {
    NSString* key = [[self.commandDelegate settings] objectForKey:@"ios_key"];
    isBackgroundLocationRunning=false;
    if (key && ![key isEqualToString:self.key]) {
        self.key = key;
        [AMapServices sharedServices].apiKey =key;
        self.locationManager = [[AMapLocationManager alloc] init];
        [self.locationManager setDelegate:self];
        [self.locationManager setPausesLocationUpdatesAutomatically:NO];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9) {
            self.locationManager.allowsBackgroundLocationUpdates = YES;
        }
        NSLog(@"cordova-plugin-gaode has been initialized. Key: %@.", key);
    }
}

- (void)startBackgroundLocation:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    serverUrl = [command.arguments objectAtIndex:0];
    interval = [[command.arguments objectAtIndex:1] intValue];
    loginName=[command.arguments objectAtIndex:2];
    if (serverUrl != nil && [serverUrl length] > 0) {
        [self.locationManager startUpdatingLocation];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"serverUrl不能为空"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager
{
    [locationManager requestAlwaysAuthorization];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didUpdateLocation:(CLLocation *)location reGeocode:(AMapLocationReGeocode *)reGeocode
{
    if(!isBackgroundLocationRunning){
        isBackgroundLocationRunning=true;
    }
    if(lastLocation ==nil){
        lastLocation=location;
        [self postToServer:serverUrl postData:location];
    }else{
        NSInteger timeDistance=[location.timestamp timeIntervalSinceDate:lastLocation.timestamp];
        if(timeDistance>=interval){
            lastLocation=location;
            [self postToServer:serverUrl postData:location];
        }
    }
    NSLog(@"location:{lat:%f; lon:%f; accuracy:%f}", location.coordinate.latitude, location.coordinate.longitude, location.horizontalAccuracy);
}

-(void)stopBackgroundLocation:(CDVInvokedUrlCommand*)command
{
    isBackgroundLocationRunning=false;
    if(self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void) postToServer:(NSString *)url postData:(CLLocation *)data
{
    NSURL *serviceUrl=[NSURL URLWithString:url];
    NSMutableURLRequest *request=[[NSMutableURLRequest alloc] init];
    request.URL=serviceUrl;
    request.HTTPMethod=@"POST";
    NSMutableData *postBody=[NSMutableData data];
    [postBody appendData:[[NSString stringWithFormat:@"loginName=%@&longitude=%f&latitude=%f&speed=%f&direction=%f",loginName,data.coordinate.longitude,data.coordinate.latitude,data.speed,data.course] dataUsingEncoding:NSUTF8StringEncoding]];
    request.HTTPBody=postBody;
    NSURLSession *session=[NSURLSession sharedSession];
    NSURLSessionTask *dataTask=[session dataTaskWithRequest: request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(!error){
            NSString *result=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@" NSLog(@上传成功：%@,error);",result);
        }else{
             NSLog(@"错误信息：%@",error);
        }
    }];
    [dataTask resume];
}

-(void) isBackgroundLocationRunning:(CDVInvokedUrlCommand*)command{
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:isBackgroundLocationRunning?1:0];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}
-(void) onceLocation:(CDVInvokedUrlCommand*)command{
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    //   定位超时时间，最低2s，此处设置为10s
    self.locationManager.locationTimeout =10;
    //   逆地理请求超时时间，最低2s，此处设置为10s
    self.locationManager.reGeocodeTimeout = 10;
    // 带逆地理（返回坐标和地址信息）。将下面代码中的 YES 改成 NO ，则不会返回地址信息。
    [self.locationManager requestLocationWithReGeocode:NO completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        CDVPluginResult* pluginResult = nil;
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];
//            if (error.code == AMapLocationErrorLocateFailed)
//            {
//
//            }
        }else{
            NSLog(@"location:%@", location);
            NSMutableDictionary *dic=[[NSMutableDictionary alloc] init];
            [dic setObject:[NSNumber numberWithDouble: location.coordinate.longitude] forKey:@"longitude"];
            [dic setObject:[NSNumber numberWithDouble: location.coordinate.latitude] forKey:@"latitude"];
            [dic setObject:[NSString stringWithFormat:@"%g", location.horizontalAccuracy] forKey:@"accuracy"];
            [dic setObject:[NSNumber numberWithDouble: location.altitude] forKey:@"altitude"];
            [dic setObject:[NSNumber numberWithDouble: location.speed] forKey:@"speed"];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dic];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

    }];
}
-(void) navigation:(CDVInvokedUrlCommand*)command{
    double startLng=[[command.arguments objectAtIndex:0] doubleValue];
    double startLat=[[command.arguments objectAtIndex:1] doubleValue];
    double endLng=[[command.arguments objectAtIndex:2] doubleValue];
    double endLat=[[command.arguments objectAtIndex:3] doubleValue];
    NSInteger navType=[[command.arguments objectAtIndex:4] integerValue];
    
    AMapNaviPoint *startPoint = [AMapNaviPoint locationWithLatitude:startLat longitude:startLng];
    AMapNaviPoint *endPoint = [AMapNaviPoint locationWithLatitude:endLat longitude:endLng];

    CDVPluginResult* pluginResult=nil;
    switch (navType) {
        case 0:
            [self initDriveView];
            [self initDriveManager];
            [self.webView addSubview:self.driveView];
            [[AMapNaviDriveManager sharedInstance] calculateDriveRouteWithStartPoints:@[startPoint]
                                                                            endPoints:@[endPoint]
                                                                            wayPoints:nil
                                                                      drivingStrategy:17];
            break;
        case 1:
            [self initWalkView];
            [self initWalkManager];
            [self.walkManager addDataRepresentative:self.walkView];
            [self.webView addSubview:self.walkView];
            [self.walkManager calculateWalkRouteWithStartPoints:@[startPoint]
                                                      endPoints:@[endPoint]];
            break;
        case 2:
            [self initRideView];
            [self initRideManager];
            [self.rideManager addDataRepresentative:self.rideView];
            [self.webView addSubview:self.rideView];
            [self.rideManager calculateRideRouteWithStartPoint:startPoint
                                                      endPoint:endPoint];
            break;
        default:
            pluginResult=[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"导航类型错误"];
            break;
    }
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)initDriveView
{
    if (self.driveView == nil)
    {
        self.driveView = [[AMapNaviDriveView alloc] initWithFrame:self.webView.bounds];
        self.driveView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        [self.driveView setDelegate:self];
//        [self.driveView setShowGreyAfterPass:YES];
//        [self.driveView setAutoZoomMapLevel:YES];
//        [self.driveView setMapViewModeType:AMapNaviViewMapModeTypeNight];
//        [self.driveView setTrackingMode:AMapNaviViewTrackingModeCarNorth];
    }
}
-(void)initWalkView{
    if(self.walkView==nil){
        self.walkView=[[AMapNaviWalkView alloc] initWithFrame:self.webView.bounds];
        [self.walkView setShowMoreButton:false];
        [self.walkView setDelegate:self];
    }
}

-(void)initRideView{
    if(self.rideView==nil){
        self.rideView=[[AMapNaviRideView alloc] initWithFrame:self.webView.bounds];
        [self.rideView setDelegate:self];
    }
}
- (void)initDriveManager
{
    [[AMapNaviDriveManager sharedInstance] setDelegate:self];
    //将driveView添加为导航数据的Representative，使其可以接收到导航诱导数据
    [[AMapNaviDriveManager sharedInstance] addDataRepresentative:self.driveView];
}
- (void)initRideManager
{
    if (self.rideManager == nil)
    {
        self.rideManager = [[AMapNaviRideManager alloc] init];
        [self.rideManager setDelegate:self];
    }
}
- (void)initWalkManager
{
    if (self.walkManager == nil)
    {
        self.walkManager = [[AMapNaviWalkManager alloc] init];
        [self.walkManager setDelegate:self];
    }
}
- (void)driveManagerOnCalculateRouteSuccess:(AMapNaviDriveManager *)driveManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    //算路成功后开始GPS导航
    [[AMapNaviDriveManager sharedInstance] startGPSNavi];
}
- (void)walkManagerOnCalculateRouteSuccess:(AMapNaviWalkManager *)walkManager
{
    NSLog(@"onCalculateRouteSuccess");
    //显示路径或开启导航
    [self.walkManager startGPSNavi];
}
- (void)rideManagerOnCalculateRouteSuccess:(AMapNaviRideManager *)rideManager
{
    NSLog(@"onCalculateRouteSuccess");
    
    //显示路径或开启导航
    [self.rideManager startGPSNavi];
}

- (void)dealloc
{
    [[AMapNaviDriveManager sharedInstance] stopNavi];
    [[AMapNaviDriveManager sharedInstance] removeDataRepresentative:self.driveView];
    [[AMapNaviDriveManager sharedInstance] setDelegate:nil];
    
    BOOL success = [AMapNaviDriveManager destroyInstance];
    NSLog(@"单例是否销毁成功 : %d",success);
    
}
-(void)dispose
{
    [[AMapNaviDriveManager sharedInstance] stopNavi];
    [[AMapNaviDriveManager sharedInstance] removeDataRepresentative:self.driveView];
    [[AMapNaviDriveManager sharedInstance] setDelegate:nil];
    
    BOOL success = [AMapNaviDriveManager destroyInstance];
    NSLog(@"单例是否销毁成功 : %d",success);
}
- (void)driveViewCloseButtonClicked:(AMapNaviDriveView *)driveView
{
    //停止导航
    [[AMapNaviDriveManager sharedInstance] stopNavi];
    [[AMapNaviDriveManager sharedInstance] removeDataRepresentative:self.driveView];
    
    //停止语音
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    [self.driveView removeFromSuperview];
    
}
-(void) walkViewCloseButtonClicked:(AMapNaviWalkView *)walkView{
    [self.walkManager stopNavi];
    [self.walkManager removeDataRepresentative:self.walkView];
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    [self.walkView removeFromSuperview];
}
-(void) rideViewMoreButtonClicked:(AMapNaviRideView *)rideView{
    [self.rideManager stopNavi];
    [self.rideManager removeDataRepresentative:self.rideView];
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
    [self.rideView removeFromSuperview];
}

- (BOOL)driveManagerIsNaviSoundPlaying:(AMapNaviDriveManager *)driveManager
{
    return [[SpeechSynthesizer sharedSpeechSynthesizer] isSpeaking];
}

- (void)driveManager:(AMapNaviDriveManager *)driveManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}

- (void)walkManager:(AMapNaviWalkManager *)walkManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType
{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}
-(void)rideManager:(AMapNaviRideManager *)rideManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType{
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}

// SDK需要实时的获取是否正在进行导航信息播报，需要开发者根据实际播报情况返回布尔值
- (BOOL)compositeManagerIsNaviSoundPlaying:(AMapNaviCompositeManager *)compositeManager {
    return [[SpeechSynthesizer sharedSpeechSynthesizer] isSpeaking];
}
// 导航播报信息回调函数
- (void)compositeManager:(AMapNaviCompositeManager *)compositeManager playNaviSoundString:(NSString *)soundString soundStringType:(AMapNaviSoundType)soundStringType {
    NSLog(@"playNaviSoundString:{%ld:%@}", (long)soundStringType, soundString);
    [[SpeechSynthesizer sharedSpeechSynthesizer] speakString:soundString];
}
// 停止导航语音播报的回调函数，当导航SDK需要停止外部语音播报时，会调用此方法
- (void)compositeManagerStopPlayNaviSound:(AMapNaviCompositeManager *)compositeManager {
    [[SpeechSynthesizer sharedSpeechSynthesizer] stopSpeak];
}
@end
