var exec = require('cordova/exec');

module.exports={
    startBackgroundLocation: function (uploadUrl,uploadInterval, loginName, success, error) {
        exec(success, error, 'gaode', 'startBackgroundLocation', [uploadUrl,uploadInterval || 10,loginName]);
    },
    stopBackgroundLocation:function (success, error) {
        exec(success, error, 'gaode', 'stopBackgroundLocation', []);
    },
    isBackgroundLocationRunning:function (success,error) {
        exec(success, error, 'gaode', 'isBackgroundLocationRunning', []);
    },
    onceLocation:function (success,error) {
        exec(success, error, 'gaode', 'onceLocation', []);
    },
    //navType 0 驾车路线规划，1 步行路线规划，2 骑行路线规划
    navigation:function (startPoint,endPoint,navType, success,error) {
        exec(success, error, 'gaode', 'navigation',
            [
                startPoint.longitude,
                startPoint.latitude,
                endPoint.longitude,
                endPoint.latitude,
                navType
            ]);
    }
}

