package org.lineageos.device.v500.navigation;

import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;

/** Set the initial Lineage taskbar preference once per user. */
public final class NavigationDefaults extends BroadcastReceiver {
    private static final Uri SYSTEM = Uri.parse("content://lineagesettings/system");
    private static final String TASKBAR = "enable_taskbar";

    @Override
    public void onReceive(Context context, Intent intent) {
        ContentResolver resolver = context.getContentResolver();
        try (Cursor cursor = resolver.query(SYSTEM, new String[] {"value"},
                "name = ?", new String[] {TASKBAR}, null)) {
            if (cursor == null) {
                return;
            }
            if (!cursor.moveToFirst()) {
                ContentValues values = new ContentValues();
                values.put("name", TASKBAR);
                values.put("value", "0");
                if (resolver.insert(SYSTEM, values) == null) {
                    return;
                }
            }
        }
        context.getPackageManager().setComponentEnabledSetting(
                new ComponentName(context, NavigationDefaults.class),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED, PackageManager.DONT_KILL_APP);
    }
}
