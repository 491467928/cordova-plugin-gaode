package xiaolong.cordova.gaode;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.util.Log;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.apache.cordova.LOG;
import org.apache.cordova.PermissionHelper;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

/**
 * This class echoes a string called from JavaScript.
 */
public class GaodePlugin extends CordovaPlugin {
    private String _serverUrl = null;
    private String _loginName = null;
    private int _interval = 10;
    private String TAG = "gaodePlugin";
    private boolean isBackgroundLocationRunning = false;
    private AMapLocation lastLocation = null;
    private String action = null;
    private JSONArray args = null;
    CallbackContext context;
    //声明AMapLocationClient类对象
    private AMapLocationClient mLocationClient = null;
    private AMapLocationClient onceLocationClient = null;
    String[] permissions = {
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.READ_PHONE_STATE
    };

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        context = callbackContext;
        this.action = action;
        this.args = args;
        if (action.equals("startBackgroundLocation")) {
            if (hasPermisssion()) {
                this.startBackgroundLocation();
            } else {
                PermissionHelper.requestPermissions(this, 0, permissions);
            }
            return true;
        }
        if (action.equals("stopBackgroundLocation")) {
            this.stopBackgroundLocation();
            return true;
        }
        if (action.equals("isBackgroundLocationRunning")) {
            context.success(isBackgroundLocationRunning ? 1 : 0);
            return true;
        }
        if (action.equals("onceLocation")) {
            if (hasPermisssion()) {
                this.onceLocation();
            } else {
                PermissionHelper.requestPermissions(this, 0, permissions);
            }
            return true;
        }
        if (action.equals("navigation")) {
            if (hasPermisssion()) {
                this.navigation();
            } else {
                PermissionHelper.requestPermissions(this, 0, permissions);
            }
            return true;
        }
        return false;
    }

    private void onceLocation() {
        Context activity = this.cordova.getActivity();
        if (onceLocationClient == null) {
            onceLocationClient = new AMapLocationClient(activity.getApplicationContext());
            AMapLocationClientOption mOption = new AMapLocationClientOption();
            mOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);//可选，设置定位模式，可选的模式有高精度、仅设备、仅网络。默认为高精度模式
            mOption.setGpsFirst(true);//可选，设置是否gps优先，只在高精度模式下有效。默认关闭
            mOption.setHttpTimeOut(30000);//可选，设置网络请求超时时间。默认为30秒。在仅设备模式下无效
            mOption.setNeedAddress(false);//可选，设置是否返回逆地理地址信息。默认是true
            mOption.setOnceLocation(true);//可选，设置是否单次定位。默认是false
            mOption.setOnceLocationLatest(true);//可选，设置是否等待wifi刷新，默认为false.如果设置为true,会自动变为单次定位，持续定位时不要使用
            AMapLocationClientOption.setLocationProtocol(AMapLocationClientOption.AMapLocationProtocol.HTTP);//可选， 设置网络请求的协议。可选HTTP或者HTTPS。默认为HTTP
            mOption.setSensorEnable(true);//可选，设置是否使用传感器。默认是false
            mOption.setWifiScan(true); //可选，设置是否开启wifi扫描。默认为true，如果设置为false会同时停止主动刷新，停止以后完全依赖于系统刷新，定位位置可能存在误差
            mOption.setLocationCacheEnable(true); //可选，设置是否使用缓存定位，默认为true
            onceLocationClient.setLocationOption(mOption);
            onceLocationClient.setLocationListener(new AMapLocationListener() {
                @Override
                public void onLocationChanged(AMapLocation location) {
                    onceLocationClient.stopLocation();
                    if (null != location) {
                        JSONObject r = new JSONObject();
                        try {
                            r.put("latitude", location.getLatitude());
                            r.put("longitude", location.getLongitude());
                            r.put("accuracy", location.getAccuracy());
                            r.put("altitude", location.getAltitude());
                            r.put("speed", location.getSpeed());
                            context.success(r);
                        } catch (JSONException e) {
                            e.printStackTrace();
                        }
                    } else {
                        context.error("定位失败");
                    }
                }
            });
        }
        onceLocationClient.startLocation();
    }

    private void startBackgroundLocation() throws JSONException {
        String serverUrl = args.getString(0);
        int interval = args.getInt(1);
        String loginName = args.getString(2);
        if (serverUrl != null && serverUrl.length() > 0) {
            this._serverUrl = serverUrl;
            this._loginName = loginName;
            this._interval = interval;
            Context activity = this.cordova.getActivity();
            if (mLocationClient == null) {
                mLocationClient = new AMapLocationClient(activity.getApplicationContext());
                mLocationClient.setLocationOption(getDefaultOption());
                mLocationClient.setLocationListener(new AMapLocationListener() {
                    @Override
                    public void onLocationChanged(AMapLocation location) {
                        if (!isBackgroundLocationRunning)
                            isBackgroundLocationRunning = true;
                        if (null != location) {
                            lastLocation = location;
                            AsynPostData(location);
                        } else {
                            context.error("定位失败");
                        }
                    }
                });
            }
            mLocationClient.startLocation();
            context.success();
        } else {
            context.error("ServerUrl不能为空");
        }
    }

    private void stopBackgroundLocation() {
        if (isBackgroundLocationRunning)
            isBackgroundLocationRunning = false;
        if (this.mLocationClient != null) {
            this.mLocationClient.stopLocation();
            this.mLocationClient = null;
            context.success();
        } else {
            context.error("未开始运行，无需结束");
        }

    }


    private void AsynPostData(AMapLocation location) {
        OkHttpClient okHttpClient = new OkHttpClient();
        RequestBody requestBody = new FormBody.Builder()
                .add("loginName", this._loginName)
                .add("longitude", String.valueOf(location.getLongitude()))
                .add("latitude", String.valueOf(location.getLatitude()))
                .add("speed", String.valueOf(location.getSpeed()))
                .add("direction", String.valueOf(location.getAccuracy()))
                .build();
        Request request = new Request.Builder()
                .url(this._serverUrl)
                .post(requestBody)
                .build();
        okHttpClient.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                LOG.d(TAG, "uploadFail" + e.getMessage());
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                LOG.d(TAG, "uploadResponse" + response.body().string());
            }
        });
    }

    private AMapLocationClientOption getDefaultOption() {
        AMapLocationClientOption mOption = new AMapLocationClientOption();
        mOption.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);//可选，设置定位模式，可选的模式有高精度、仅设备、仅网络。默认为高精度模式
        mOption.setGpsFirst(true);//可选，设置是否gps优先，只在高精度模式下有效。默认关闭
        mOption.setHttpTimeOut(30000);//可选，设置网络请求超时时间。默认为30秒。在仅设备模式下无效
        mOption.setInterval(this._interval * 1000);//可选，设置定位间隔。默认为2秒
        mOption.setNeedAddress(false);//可选，设置是否返回逆地理地址信息。默认是true
        mOption.setOnceLocation(false);//可选，设置是否单次定位。默认是false
        mOption.setOnceLocationLatest(false);//可选，设置是否等待wifi刷新，默认为false.如果设置为true,会自动变为单次定位，持续定位时不要使用
        AMapLocationClientOption.setLocationProtocol(AMapLocationClientOption.AMapLocationProtocol.HTTP);//可选， 设置网络请求的协议。可选HTTP或者HTTPS。默认为HTTP
        mOption.setSensorEnable(true);//可选，设置是否使用传感器。默认是false
        mOption.setWifiScan(true); //可选，设置是否开启wifi扫描。默认为true，如果设置为false会同时停止主动刷新，停止以后完全依赖于系统刷新，定位位置可能存在误差
        mOption.setLocationCacheEnable(true); //可选，设置是否使用缓存定位，默认为true
        return mOption;
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions,
                                          int[] grantResults) throws JSONException {
        PluginResult result;
        //This is important if we're using Cordova without using Cordova, but we have the geolocation plugin installed
        if (context != null) {
            for (int r : grantResults) {
                if (r == PackageManager.PERMISSION_DENIED) {
                    LOG.d(TAG, "Permission Denied!");
                    result = new PluginResult(PluginResult.Status.ILLEGAL_ACCESS_EXCEPTION);
                    context.sendPluginResult(result);
                    return;
                }

            }
            this.execute(this.action, this.args, this.context);
        }
    }

    private void navigation() throws JSONException {
        Intent intent = new Intent();
        intent.setClass(this.cordova.getActivity().getApplicationContext(), NavigationActivity.class);

        intent.putExtra("StartLng", args.getString(0));
        intent.putExtra("StartLat", args.getString(1));
        intent.putExtra("EndLng", args.getString(2));
        intent.putExtra("EndLat", args.getString(3));
        intent.putExtra("NavType", args.getString(4));

        this.cordova.startActivityForResult((CordovaPlugin) this, intent, 100);
    }

    public boolean hasPermisssion() {
        for (String p : permissions) {
            if (!PermissionHelper.hasPermission(this, p)) {
                return false;
            }
        }
        return true;
    }
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        if(requestCode == 100){
            PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
            context.sendPluginResult(pluginResult);
        }
    }
}
