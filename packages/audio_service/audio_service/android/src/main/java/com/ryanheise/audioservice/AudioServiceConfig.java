package com.ryanheise.audioservice;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import java.util.Iterator;
import java.util.Map;
import org.json.JSONObject;

public class AudioServiceConfig {
    private static final String SHARED_PREFERENCES_NAME = "audio_service_preferences";
    private static final String KEY_ANDROID_RESUME_ON_CLICK = "androidResumeOnClick";
    private static final String KEY_ANDROID_NOTIFICATION_CHANNEL_ID = "androidNotificationChannelId";
    private static final String KEY_ANDROID_NOTIFICATION_CHANNEL_NAME = "androidNotificationChannelName";
    private static final String KEY_ANDROID_NOTIFICATION_CHANNEL_DESCRIPTION = "androidNotificationChannelDescription";
    private static final String KEY_NOTIFICATION_COLOR = "notificationColor";
    private static final String KEY_ANDROID_NOTIFICATION_ICON = "androidNotificationIcon";
    private static final String KEY_ANDROID_SHOW_NOTIFICATION_BADGE = "androidShowNotificationBadge";
    private static final String KEY_ANDROID_NOTIFICATION_CLICK_STARTS_ACTIVITY = "androidNotificationClickStartsActivity";
    private static final String KEY_ANDROID_NOTIFICATION_ONGOING = "androidNotificationOngoing";
    private static final String KEY_ANDROID_STOP_FOREGROUND_ON_PAUSE = "androidStopForegroundOnPause";
    private static final String KEY_ART_DOWNSCALE_WIDTH = "artDownscaleWidth";
    private static final String KEY_ART_DOWNSCALE_HEIGHT = "artDownscaleHeight";
    private static final String KEY_ACTIVITY_CLASS_NAME = "activityClassName";
    private static final String KEY_BROWSABLE_ROOT_EXTRAS = "androidBrowsableRootExtras";

    private SharedPreferences preferences;
    public boolean androidResumeOnClick;
    public String androidNotificationChannelId;
    public String androidNotificationChannelName;
    public String androidNotificationChannelDescription;
    public int notificationColor;
    public String androidNotificationIcon;
    public boolean androidShowNotificationBadge;
    public boolean androidNotificationClickStartsActivity;
    public boolean androidNotificationOngoing;
    public boolean androidStopForegroundOnPause;
    public int artDownscaleWidth;
    public int artDownscaleHeight;
    public String activityClassName;
    public String browsableRootExtras;

    public AudioServiceConfig(Context context) {
        preferences = context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE);
        androidResumeOnClick = preferences.getBoolean(KEY_ANDROID_RESUME_ON_CLICK, true);
        androidNotificationChannelId = preferences.getString(KEY_ANDROID_NOTIFICATION_CHANNEL_ID, null);
        androidNotificationChannelName = preferences.getString(KEY_ANDROID_NOTIFICATION_CHANNEL_NAME, null);
        androidNotificationChannelDescription = preferences.getString(KEY_ANDROID_NOTIFICATION_CHANNEL_DESCRIPTION, null);
        notificationColor = preferences.getInt(KEY_NOTIFICATION_COLOR, -1);
        androidNotificationIcon = preferences.getString(KEY_ANDROID_NOTIFICATION_ICON, "mipmap/ic_launcher");
        androidShowNotificationBadge = preferences.getBoolean(KEY_ANDROID_SHOW_NOTIFICATION_BADGE, false);
        androidNotificationClickStartsActivity = preferences.getBoolean(KEY_ANDROID_NOTIFICATION_CLICK_STARTS_ACTIVITY, true);
        androidNotificationOngoing = preferences.getBoolean(KEY_ANDROID_NOTIFICATION_ONGOING, false);
        androidStopForegroundOnPause = preferences.getBoolean(KEY_ANDROID_STOP_FOREGROUND_ON_PAUSE, true);
        artDownscaleWidth = preferences.getInt(KEY_ART_DOWNSCALE_WIDTH, -1);
        artDownscaleHeight = preferences.getInt(KEY_ART_DOWNSCALE_HEIGHT, -1);
        activityClassName = preferences.getString(KEY_ACTIVITY_CLASS_NAME, null);
        browsableRootExtras = preferences.getString(KEY_BROWSABLE_ROOT_EXTRAS, null);
    }

    public void setBrowsableRootExtras(Map<?,?> map) {
        if (map != null) {
            JSONObject json = new JSONObject(map);
            browsableRootExtras = json.toString();
        } else {
            browsableRootExtras = null;
        }
    }

    public Bundle getBrowsableRootExtras() {
        if (browsableRootExtras == null) return null;
        try {
            JSONObject json = new JSONObject(browsableRootExtras);
            Bundle extras = new Bundle();
            for (Iterator<String> it = json.keys(); it.hasNext();) {
                String key = it.next();
                try {
                    extras.putInt(key, json.getInt(key));
                } catch (Exception e1) {
                    try {
                        extras.putBoolean(key, json.getBoolean(key));
                    } catch (Exception e2) {
                        try {
                            extras.putDouble(key, json.getDouble(key));
                        } catch (Exception e3) {
                            try {
                                extras.putString(key, json.getString(key));
                            } catch (Exception e4) {
                                System.out.println("Unsupported extras value for key " + key);
                            }
                        }
                    }
                }
            }
            return extras;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    public void save() {
        preferences.edit()
            .putBoolean(KEY_ANDROID_RESUME_ON_CLICK, androidResumeOnClick)
            .putString(KEY_ANDROID_NOTIFICATION_CHANNEL_ID, androidNotificationChannelId)
            .putString(KEY_ANDROID_NOTIFICATION_CHANNEL_NAME, androidNotificationChannelName)
            .putString(KEY_ANDROID_NOTIFICATION_CHANNEL_DESCRIPTION, androidNotificationChannelDescription)
            .putInt(KEY_NOTIFICATION_COLOR, notificationColor)
            .putString(KEY_ANDROID_NOTIFICATION_ICON, androidNotificationIcon)
            .putBoolean(KEY_ANDROID_SHOW_NOTIFICATION_BADGE, androidShowNotificationBadge)
            .putBoolean(KEY_ANDROID_NOTIFICATION_CLICK_STARTS_ACTIVITY, androidNotificationClickStartsActivity)
            .putBoolean(KEY_ANDROID_NOTIFICATION_ONGOING, androidNotificationOngoing)
            .putBoolean(KEY_ANDROID_STOP_FOREGROUND_ON_PAUSE, androidStopForegroundOnPause)
            .putInt(KEY_ART_DOWNSCALE_WIDTH, artDownscaleWidth)
            .putInt(KEY_ART_DOWNSCALE_HEIGHT, artDownscaleHeight)
            .putString(KEY_ACTIVITY_CLASS_NAME, activityClassName)
            .putString(KEY_BROWSABLE_ROOT_EXTRAS, browsableRootExtras)
            .apply();
    }
}
