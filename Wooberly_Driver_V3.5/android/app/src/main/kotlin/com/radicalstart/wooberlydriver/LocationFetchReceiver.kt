package com.radicalstart.wooberlydriver

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.widget.Toast


class LocationFetchReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (exactAlarmIsAllowed(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)) {
            AppService.startService(context, auth, userId, deviceID)
        }
    }
}

class AlarmPermissionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED) {
            if (exactAlarmIsAllowed(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager)) {
                AppService.startService(context, auth, userId, deviceID)
            }
        }
    }
}

private fun exactAlarmIsAllowed(alarmManager: AlarmManager): Boolean {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        alarmManager.canScheduleExactAlarms()
    } else {
        true
    }
}