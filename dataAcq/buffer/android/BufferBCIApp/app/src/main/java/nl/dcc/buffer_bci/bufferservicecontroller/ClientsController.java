package nl.dcc.buffer_bci.bufferservicecontroller;

import android.app.ActivityManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import nl.dcc.buffer_bci.C;
import nl.dcc.buffer_bci.bufferclientsservice.ThreadInfo;
import nl.dcc.buffer_bci.bufferclientsservice.base.Argument;

import java.util.*;

/**
 * Created by georgedimitriadis on 08/02/15.
 */
public class ClientsController {

    public final static int TYPE_INTEGER_SIGNED = 0;
    public final static int TYPE_DOUBLE_SIGNED = 1;
    public final static int TYPE_BOOLEAN = 2;
    public final static int TYPE_STRING = 3;
    public final static int TYPE_RADIO = 4;
    public final static int TYPE_CHECK = 5;
    public final static int TYPE_INTEGER_UNSIGNED = 6;
    public final static int TYPE_DOUBLE_UNSIGNED = 7;
    public static String TAG = ClientsController.class.getSimpleName();
    private final LinkedHashMap<Integer, ThreadInfo> threadInfos = new LinkedHashMap<Integer, ThreadInfo>();
    Context context;
    Intent intent;
    private String clientsServicePackageName = C.CLIENTS_SERVICE_PACKAGE_NAME;
    private String clientsServiceClassName = C.CLIENTS_SERVICE_CLASS_NAME;
    private LinkedHashMap<Integer, Argument[]> allArguments = new LinkedHashMap<Integer, Argument[]>();
    private List<Integer> threadIDs=new ArrayList<Integer>();
    private int port = 1972;


    ClientsController(Context context) {
        this.context = context;
        intent = new Intent();
        intent.setClassName(clientsServicePackageName, clientsServiceClassName);
    }

    public static Object getKeyFromValue(Map hm, Object value) {
        for (Object o : hm.keySet()) {
            if (hm.get(o).equals(value)) {
                return o;
            }
        }
        return null;
    }

    public String toString() {
        String ret = "ClientsController{}";
        if (threadIDs!=null && threadIDs.size() > 0) {
            ret += " with \n";
            for (int id : threadIDs)
                ret += "\t" + threadInfos.get(id).toString() + "\n";
        }
        return ret;
    }

    protected boolean isThreadsServiceRunning() {
        final ActivityManager manager = (ActivityManager) context.getSystemService(context.ACTIVITY_SERVICE);
        for (final ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (service.service.getClassName().equals(clientsServiceClassName)) {
                return true;
            }
        }
        return false;
    }

    protected void updateThreadInfoAndArguments(ThreadInfo threadInfo, Argument[] arguments) {
        if (threadInfos.size() == 0) {
            threadInfos.put(threadInfo.threadID, threadInfo);
            allArguments.put(threadInfo.threadID, arguments);
            threadIDs.add(threadInfo.threadID);
        }

        if (threadIDs.contains(threadInfo.threadID)) {
            threadInfos.remove(threadInfo.threadID);
            threadInfos.put(threadInfo.threadID, threadInfo);
            allArguments.remove(threadInfo.threadID);
            allArguments.put(threadInfo.threadID, arguments);
        } else {
            threadInfos.put(threadInfo.threadID, threadInfo);
            allArguments.put(threadInfo.threadID, arguments);
            threadIDs.add(threadInfo.threadID);
        }
        Log.i(TAG, "Updated Thread:" + threadInfo.title + "(" + arguments.length + " args)");
        Log.i(TAG, "Now : " + threadInfos.size() + " threadInfos and " + threadIDs.size() + "threadIDs");
    }

    // Interface
    //Clients service controls
    public String startThreadsService() {
        try {
            intent.putExtra("port", port);
        } catch (final NumberFormatException e) {
            intent.putExtra("port", 1972);
        }
        //threadInfos = new LinkedHashMap<Integer, ThreadInfo>();
        //allArguments = new LinkedHashMap<Integer, Argument[]>();
        //threadIDs = new ArrayList<Integer>();

        // Start the client.
        Log.i(TAG, "Attempting to start Clients Service");
        ComponentName serviceName = context.startService(intent);
        Log.i(TAG, "Managed to start service: " + serviceName);

        String result = "Clients Service was not found";
        if (serviceName != null) result = serviceName.toString();
        return result;
    }


    public boolean stopThreadsService() {
        boolean stopped = context.stopService(intent);
        Log.i(TAG, "Trying to stop clients service: " + stopped);
        if (threadInfos != null )  threadInfos.clear();
        if (threadIDs != null)     threadIDs.clear();
        if (allArguments != null)  allArguments.clear();
        return stopped;
    }

    public int getNumberOfThreads() {
        return threadInfos.size();
    }

    public int[] getAllThreadIDs() {
        if (threadIDs != null) {
            int[] result = new int[threadIDs.size()];
            for (int i = 0; i < threadIDs.size(); ++i) {
                result[i] = threadIDs.get(i);
                //Log.i(TAG, "id: " + result[i]);
            }
            return result;
        }
        return new int[]{};
    }

    public String[] getAllThreadNames() {
        String[] result = new String[threadInfos.size()];
        int i = 0;
        for (ThreadInfo threadInfo : threadInfos.values()) {
            result[i] = threadInfo.title;
            i++;
        }
        return result;
    }

    public String[] getAllThreadNamesAndIDs() {
        String[] result = new String[threadInfos.size()];
        Collection<ThreadInfo> allThreadInfos = threadInfos.values();
        int i = 0;
        for (ThreadInfo threadinfo : allThreadInfos) {
            result[i] = threadinfo.threadID + ":" + threadinfo.title;
            i += 1;
        }
        return result;
    }


    public void startThread(int threadID) {
        Intent intentStart = new Intent(C.FILTER_FOR_CLIENTS);
        intentStart.putExtra(C.MESSAGE_TYPE, C.THREAD_START);
        intentStart.putExtra(C.THREAD_ID, threadID);
        Log.i(TAG, "Sending Thread Start with ID: " + threadID);
        context.sendOrderedBroadcast(intentStart, null);
    }

    public void pauseThread(int threadID) {

    }

    public void stopThread(int threadID) {
        Intent intentStart = new Intent(C.FILTER_FOR_CLIENTS);
        intentStart.putExtra(C.MESSAGE_TYPE, C.THREAD_STOP);
        intentStart.putExtra(C.THREAD_ID, threadID);
        Log.i(TAG, "Sending Thread Stop with ID: " + threadID);
        context.sendOrderedBroadcast(intentStart, null);
    }

    public int getNumberOfArgumentsInThread(int threadID) {
        return allArguments.get(threadID).length;
    }

    //Does not implement TYPE_CHECK and TYPE_RADIO
    //Creates an array of strings, each with "argumentDescription:argumentValue" for each argument
    public String[] getThreadArguments(int threadID) {
        Argument[] arguments = allArguments.get(threadID);
        String[] result = new String[arguments.length];

        int i = 0;
        for (Argument argument : arguments) {
            int type = argument.getType();
            result[i] = argument.getDescription() + ":";
            switch (type) {
                case TYPE_INTEGER_SIGNED:
                case TYPE_INTEGER_UNSIGNED:
                    result[i] += argument.getInteger().toString();
                    break;
                case TYPE_DOUBLE_SIGNED:
                case TYPE_DOUBLE_UNSIGNED:
                    result[i] += argument.getDouble().toString();
                    break;
                case TYPE_BOOLEAN:
                    result[i] += argument.getBoolean().toString();
                    break;
                case TYPE_STRING:
                    result[i] += argument.getString();
                    break;
            }
        }
        return result;
    }

    //Assumes that the argument String carries the argument info as:
    //ArgDescription:ArgType:ArgValue where the ArgType is the corresponding int
    public void setThreadArgument(int threadID, String argument) {


    }

    public String getThreadStatus(int threadID) {
        synchronized (threadInfos) {
            return threadInfos.get(threadID).status;
        }
    }

    public boolean getThreadRunning(int threadID) {
        synchronized (threadInfos) {
            return threadInfos.get(threadID).running;
        }
    }

    public String getThreadTitle(int threadID) {
        synchronized (threadInfos) {
            return threadInfos.get(threadID).title;
        }
    }


    public void reloadAllThreads() {
        Intent intent = new Intent(C.FILTER_FOR_CLIENTS);
        intent.putExtra(C.MESSAGE_TYPE, C.THREAD_INFO_BROADCAST);
        Log.i(TAG, "Refreshing all threads info");
        context.sendOrderedBroadcast(intent, null);
    }
}
