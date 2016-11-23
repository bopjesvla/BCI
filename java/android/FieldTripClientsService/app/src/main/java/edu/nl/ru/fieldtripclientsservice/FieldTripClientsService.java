package edu.nl.ru.fieldtripclientsservice;

import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiManager.WifiLock;
import android.os.*;
import android.os.PowerManager.WakeLock;
import android.support.v4.app.NotificationCompat;
import android.util.Log;
import android.util.SparseArray;
import android.widget.Toast;
import edu.nl.ru.fieldtripclientsservice.base.AndroidHandle;
import edu.nl.ru.fieldtripclientsservice.base.Argument;
import edu.nl.ru.fieldtripclientsservice.base.ThreadBase;
import edu.nl.ru.fieldtripclientsservice.threads.ThreadList;

import java.io.*;

/**
 * Manages FieldTrip Buffer clients that communicates with the server.
 */
public class FieldTripClientsService extends Service {

    private final String TAG = FieldTripClientsService.class.toString();
    private final SparseArray<ThreadBase> threads = new SparseArray<ThreadBase>();
    private final SparseArray<WrapperThread> wrappers = new SparseArray<WrapperThread>();
    private final SparseArray<ThreadInfo> threadInfos = new SparseArray<ThreadInfo>();
    private final Handler handler = new Handler();
    private IntentFilter intentFilter = new IntentFilter(C.FILTER_FOR_CLIENTS);
    private WakeLock wakeLock;
    private WifiLock wifiLock;
    private Updater updater;
    private final BroadcastReceiver mMessageReceiver = new BroadcastReceiver() {

        @Override
        public void onReceive(final Context context, final Intent intent) {
            int id;
            switch (intent.getIntExtra(C.MESSAGE_TYPE, -1)) {
                case C.THREAD_STOP:
                    id = intent.getIntExtra(C.THREAD_ID, -1);
                    Log.i(TAG, "Stopping Thread with ID: " + id);
                    if (id != -1) {
                        threads.get(id).stop();
                        threadInfos.get(id).running = false;
                        updater.update = false;
                    }
                    break;
                case C.THREAD_PAUSE:
                    id = intent.getIntExtra(C.THREAD_ID, -1);
                    Log.i(TAG, "Stopping Thread with ID: " + id);
                    threads.get(id).stop();
                    threadInfos.get(id).running = false;
                    updater.update = false;
                    break;
                case C.THREAD_START:
                    id = intent.getIntExtra(C.THREAD_ID, -1);
                    if (wrappers.get(id).started) {
                        Log.i(TAG, "Restarting Thread with ID: " + id);
                        wrappers.setValueAt(id, new WrapperThread(wrappers.get(id).base));
                    } else
                        Log.i(TAG, "Starting Thread with ID: " + id);
                    wrappers.get(id).start();
                    threadInfos.get(id).running = true;
                    updater.update = true;
                    break;
                case C.THREAD_UPDATE_ARGUMENTS:
                    id = intent.getIntExtra(C.THREAD_ID, -1);
                    int numOfArgs = intent.getIntExtra(C.THREAD_N_ARGUMENTS, 0);
                    Argument[] arguments = new Argument[numOfArgs];
                    for (int i = 0; i < numOfArgs; ++i) {
                        arguments[i] = (Argument) intent.getSerializableExtra(C.THREAD_ARGUMENTS + i);
                    }
                    threads.get(id).setArguments(arguments);
                    updater.update = true;
                    break;
                case C.THREAD_UPDATE_ARG_FROM_STR:
                    String argumentAsString = intent.getStringExtra(C.THREAD_STRING_FOR_ARG);
                    id = intent.getIntExtra(C.THREAD_ID, -1);
                    String argDescription = argumentAsString.split(":")[0];
                    int argType = Integer.getInteger(argumentAsString.split(":")[1]);
                    String argValueStr = argumentAsString.split(":")[2];
                    Log.i(TAG, "Received Argument " + argDescription + " to update in thread " + id + " with value "
                            + argValueStr);
                    Argument argument;
                    switch (argType) {
                        case Argument.TYPE_BOOLEAN:
                            argument = new Argument(argDescription, String.valueOf(argValueStr));
                            break;
                        case Argument.TYPE_DOUBLE_SIGNED:
                        case Argument.TYPE_DOUBLE_UNSIGNED:
                            argument = new Argument(argDescription, String.valueOf(argValueStr));
                            break;
                        case Argument.TYPE_INTEGER_SIGNED:
                        case Argument.TYPE_INTEGER_UNSIGNED:
                            argument = new Argument(argDescription, String.valueOf(argValueStr));
                            break;
                        case Argument.TYPE_STRING:
                        default:
                            argument = new Argument(argDescription, argValueStr);
                            break;
                    }
                    threads.get(id).setArgument(argument);
                    updater.update = true;
                    break;
                default:
            }
        }

    };

    public void handleExceptionClose(final Exception e, final ThreadBase base) {
        Log.e(TAG, Log.getStackTraceString(e));
        makeToast(base.getName() + " closed", Toast.LENGTH_SHORT);
        try {
            if (isExternalStorageWritable()) {

                PrintWriter writer = new PrintWriter(new FileOutputStream(new File(Environment
                        .getExternalStorageDirectory(), "Stack_trace_" + base.getName())));

                e.printStackTrace(writer);
                writer.flush();
                makeToast("Stack trace written to " + "Stack_trace_" + base.getName(), Toast.LENGTH_SHORT);

            } else {

                throw new IOException("Could not open external storage.");
            }
        } catch (IOException e1) {
            makeToast("Failed to write stack trace!", Toast.LENGTH_LONG);
        }
    }

    public void handleExceptionCrash(final Exception e, final ThreadBase base) {
        Log.e(TAG, Log.getStackTraceString(e));
        try {
            if (isExternalStorageWritable()) {

                PrintWriter writer = new PrintWriter(new FileOutputStream(new File(Environment
                        .getExternalStorageDirectory(), "Stack_trace_" + base.getName())));

                e.printStackTrace(writer);
                writer.flush();
                makeToast("Stack trace written to " + "Stack_trace_" + base.getName(), Toast.LENGTH_SHORT);

            } else {

                throw new IOException("Could not open external storage.");
            }
        } catch (IOException e1) {
            makeToast("Failed to write stack trace!", Toast.LENGTH_LONG);
        }
    }

    /* Checks if external storage is available to at least read */
    public boolean isExternalStorageReadable() {
        String state = Environment.getExternalStorageState();
        return Environment.MEDIA_MOUNTED.equals(state) || Environment.MEDIA_MOUNTED_READ_ONLY.equals(state);
    }

    /* Checks if external storage is available for read and write */
    public boolean isExternalStorageWritable() {
        String state = Environment.getExternalStorageState();
        return Environment.MEDIA_MOUNTED.equals(state);
    }

    private void makeToast(final String message, final int duration) {
        Runnable r = new Runnable() {
            @Override
            public void run() {
                Toast.makeText(getApplicationContext(), message, duration).show();
            }
        };

        handler.post(r);
    }

    @Override
    public IBinder onBind(final Intent intent) {
        return null;
    }

    /**
     * Called when the service is stopped. Stops the buffer.
     */
    @Override
    public void onDestroy() {
        Log.i(TAG, "Stopping Thread Service.");

        if (wakeLock != null) {
            wakeLock.release();
        }
        if (wifiLock != null) {
            wifiLock.release();
        }
        if (updater != null) {
            updater.stopUpdating();
        }
        for (int i = 0; i < threadInfos.size(); i++) {
            int id = threadInfos.valueAt(i).threadID;
            try {
                threads.get(id).stop();
            } catch (Exception e) {
                handleExceptionClose(e, threads.get(id));
            }
        }
        this.unregisterReceiver(mMessageReceiver);
    }

    @Override
    public int onStartCommand(final Intent intent, final int flags, final int startId) {

        if (wakeLock == null && wifiLock == null) {
            updater = new Updater(this);
            updater.start();
            updater.update = false;
            final int port = intent.getIntExtra("port", 1972);

            // Get Wakelocks
            final PowerManager powerManager = (PowerManager) getSystemService(POWER_SERVICE);
            wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, C.WAKELOCKTAG);
            wakeLock.acquire();

            final WifiManager wifiMan = (WifiManager) getSystemService(WIFI_SERVICE);
            wifiLock = wifiMan.createWifiLock(C.WAKELOCKTAGWIFI);
            wifiLock.acquire();

            // Create Foreground Notification
            // Create notification text
            final Resources res = getResources();
            final String notification_text = res.getString(R.string.notification_text);
            final NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(this).setSmallIcon(R.drawable
                    .ic_launcher).setContentTitle(res.getString(R.string.notification_title)).setContentText
                    (notification_text);

            // Turn this service into a foreground service
            startForeground(1, mBuilder.build());
            Log.i(TAG, "Fieldtrip Clients Service moved to foreground.");
        }

        createAllThreadsAndBroadcastInfo();

        if (threads != null) {
            this.registerReceiver(mMessageReceiver, intentFilter);
        }

        return START_NOT_STICKY;
    }

    private void createAllThreadsAndBroadcastInfo() {

        updater.update = false;
        Class[] allThreads = ThreadList.list;
        int numOfThreads = allThreads.length;
        Log.i(TAG, "Number of Threads = " + numOfThreads);
        for (int i = 0; i < numOfThreads; ++i) {
            Class c = ThreadList.list[i];
            try {
                ThreadBase thread = (ThreadBase) c.newInstance();
                Argument[] arguments = thread.getArguments();

                try {
                    thread.setArguments(arguments);
                    thread.setHandle(new Handle(this, i));
                } catch (Exception e) {
                    handleExceptionCrash(e, thread);
                }

                for (Argument a : arguments) {
                    a.validate();
                }
                thread.validateArguments(arguments);

                for (Argument a : arguments) {
                    if (a.isInvalid()) {
                        Log.e(TAG, "Argument: " + a.getDescription() + " is invalid");
                        return;
                    }
                }

                threads.put(i, thread);
                WrapperThread wrapper = new WrapperThread(thread);
                wrappers.put(i, wrapper);

                Log.i(TAG, "Number of Arguments = " + wrapper.base.arguments.length);
                Log.i(TAG, "First argument is: " + wrapper.base.arguments[0].getDescription() + " with type: " +
                        wrapper.base.arguments[0].getType());

                ThreadInfo threadInfo = new ThreadInfo(i, wrapper.getName(), "", false);
                threadInfos.put(i, threadInfo);

                Intent intent = new Intent(C.SEND_UPDATE_INFO_TO_CONTROLLER_ACTION);
                intent.putExtra(C.MESSAGE_TYPE, C.UPDATE);
                intent.putExtra(C.IS_THREAD_INFO, true);
                intent.putExtra(C.THREAD_INFO, threadInfo);
                intent.putExtra(C.THREAD_INDEX, threadInfo.threadID);
                intent.putExtra(C.THREAD_N_ARGUMENTS, arguments.length);
                for (int k = 0; k < arguments.length; k++) {
                    intent.putExtra(C.THREAD_ARGUMENTS + k, arguments[k]);
                }
                Log.i(TAG, "Sending broadcast with ThreadID = " + threadInfo.threadID);
                sendOrderedBroadcast(intent, null);

                try {
                    Thread.sleep(100);
                } catch (InterruptedException e) {
                    Log.e(TAG, "Exception during sleeping. Very exceptional!");
                    Log.e(TAG, Log.getStackTraceString(e));
                }

            } catch (InstantiationException e) {
                Log.w(TAG, "Instantiation failed!");
            } catch (IllegalAccessException e) {
                Log.w(TAG, "Instantiation failed!");
            }
        }
    }

    private class Handle implements AndroidHandle {
        private final Context context;
        private final int threadID;

        public Handle(final Context context, final int threadID) {
            this.context = context;
            this.threadID = threadID;
        }

        @Override
        public FileInputStream openReadFile(final String path) throws IOException {
            if (isExternalStorageReadable()) {
                return new FileInputStream(new File(Environment.getExternalStorageDirectory(), path));
            } else {
                throw new IOException("Could not open external storage.");
            }
        }

        public InputStream openAsset(final String path) throws IOException {
            return context.getAssets().open(path);
        }

        @Override
        public FileOutputStream openWriteFile(final String path) throws IOException {
            if (isExternalStorageWritable()) {
                return new FileOutputStream(new File(Environment.getExternalStorageDirectory(), path));
            } else {
                throw new IOException("Could not open external storage.");
            }
        }

        @Override
        public void toast(final String message) {
            makeToast(message, Toast.LENGTH_SHORT);
        }

        @Override
        public void toastLong(final String message) {
            makeToast(message, Toast.LENGTH_LONG);
        }

        @Override
        public void updateStatus(final String status) {
            synchronized (threadInfos) {
                threadInfos.get(threadID).status = status;
            }
        }
    }

    private class Updater extends Thread {

        private final Context context;
        protected boolean update = true;
        private boolean run = true;

        public Updater(final Context context) {
            this.context = context;
        }

        @Override
        public void run() {
            while (run) {
                try {
                    Thread.sleep(1000);
                    if (update) {
                        sendUpdates();
                    }
                } catch (InterruptedException e) {
                    Log.e(TAG, "Exception during sleeping. Very exceptional");
                    Log.e(TAG, Log.getStackTraceString(e));
                }
            }
        }

        private void sendUpdates() {

            int numOfThreads = threads.size();
            for (int i = 0; i < numOfThreads; ++i) {
                int id = threads.keyAt(i);

                Argument[] arguments = threads.get(id).getArguments();

                Intent intent = new Intent(C.SEND_UPDATE_INFO_TO_CONTROLLER_ACTION);
                intent.putExtra(C.MESSAGE_TYPE, C.UPDATE);
                intent.putExtra(C.IS_THREAD_INFO, true);

                threadInfos.get(id).running = wrappers.get(id).isAlive();

                intent.putExtra(C.THREAD_INFO, threadInfos.get(id));
                intent.putExtra(C.THREAD_INDEX, i);
                intent.putExtra(C.THREAD_N_ARGUMENTS, arguments.length);

                for (int k = 0; k < arguments.length; k++) {
                    intent.putExtra(C.THREAD_ARGUMENTS + k, arguments[k]);
                }
                //Log.i(TAG, "Sending update broadcast with ThreadID = "+threadInfos.get(id).threadID);
                sendOrderedBroadcast(intent, null);
            }

        }

        public void stopUpdating() {
            run = false;
        }
    }

    private class WrapperThread extends Thread {

        public final ThreadBase base;
        protected boolean started;

        public WrapperThread(final ThreadBase base) {
            this.base = base;
            setName(base.getName());
            started = false;
        }

        @Override
        public void run() {
            if (!started) {
                Looper.prepare();
                started = true;
            }
            try {
                base.mainloop();
            } catch (Exception e) {
                handleExceptionCrash(e, base);
            }
        }

    }

}
