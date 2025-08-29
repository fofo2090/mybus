package com.example.mybus;

import android.app.Application;
import androidx.multidex.MultiDexApplication;

public class MainApplication extends MultiDexApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        // تهيئة إضافية إذا لزم الأمر
    }
}