package com.radicalstart.wooberlydriver

import android.app.Activity
import android.app.Application
import android.os.Bundle

object LifecycleDetector {

    val activityLifecycleCallbacks: Application.ActivityLifecycleCallbacks =
        ActivityLifecycleCallbacks()

    var listener: Listener? = null

    var isActivityRunning = false
        private set

    interface Listener {

        fun onFlutterActivityCreated()

        fun onFlutterActivityDestroyed()

    }

    private class ActivityLifecycleCallbacks : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(p0: Activity, p1: Bundle?) {
            if (p0 is MainActivity) {
                isActivityRunning = true
                listener?.onFlutterActivityCreated()
            }
        }

        override fun onActivityStarted(p0: Activity) {

        }

        override fun onActivityResumed(p0: Activity) {

        }

        override fun onActivityPaused(p0: Activity) {

        }

        override fun onActivityStopped(p0: Activity) {

        }

        override fun onActivitySaveInstanceState(p0: Activity, p1: Bundle) {

        }

        override fun onActivityDestroyed(p0: Activity) {
            if (p0 is MainActivity) {
                isActivityRunning = false
                listener?.onFlutterActivityDestroyed()
            }
        }


    }
}