#安装
cordova plugin add cordova-plugin-gaode --variable ios_key=XXXXX --variable android_key=XXXXXXX

请把XXXXXX替换成对应的高德应用的key

#用法
```Javascript
//uploadUrl  接受GPS数据的服务端地址
//interval 上传间隔时间
//loginName 用户名(非必须)
cordova.plugin.gaode.startBackgroundLocation(
    uploadUrl,
    interval,
    loginName,
    ()=>{console.log('ok')},
    e=>{
            console.log(e);
    }
);
```
停止后台定位上传功能
```Javascript
cordova.plugin.gaode.stopBackgroundLocation(
    ()=>{console.log('ok')},
    e=>{console.log(e)}
)
```
判断是否后端定位运行中
```Javascript
cordova.plugin.gaode.isBackgroundLocationRunning(
    (ret)=>{
        //返回数字1或者0，1表示后台定位运行中，0表示未开启后台定位
        console.log(ret);
    },
    e=>{console.log(e)}
)
```
单次定位
```Javascript
cordova.plugin.gaode.onceLocation(
    (data)=>{
       //返回JSON数据
       //{
       //    longitude:精度,
       //    latitude:纬度,
       //    accuracy:水平精准度
       //    altitude:高度,
       //    speed:速度
       //}
    },
    e=>{console.log(e)}
)
```
唤起导航

```Javascript
起点终点的格式
{
    longitude:经度
    latitude:维度
}
导航方式：0 驾车路线规划，1 步行路线规划，2 骑行路线规划 
cordova.plugin.gaode.navigation(
    起点,
    终点,
    导航方式,
    ()=>{
       //导航界面关闭后回调
    },
    e=>{
        //错误码
        //https://lbs.amap.com/api/ios-navi-sdk/guide/tools/errorcode
        console.log(e)
    }
)
```
