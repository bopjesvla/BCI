package edu.nl.ru.monitor;

import android.os.Parcel;
import android.os.Parcelable;

import edu.nl.ru.fieldtripbufferservicecontroller.C;

public class ClientInfo implements Parcelable {
    private static final long serialVersionUID = -5926084016803995132L;

	public final String address;
	public final int clientID;
	public int samplesGotten = 0;
	public int samplesPut = 0;
	public int eventsGotten = 0;
	public int eventsPut = 0;
	public int lastActivity = 0;
	public int waitEvents = -1;
	public int waitSamples = -1;
	public int error = -1;
	public long timeLastActivity = 0;
	public long time = 0;
	public long waitTimeout = -1;
	public boolean connected = true;
	public boolean changed = true;
	public int diff = 0;

	public static final Parcelable.Creator<ClientInfo> CREATOR = new Parcelable.Creator<ClientInfo>() {
		@Override
		public ClientInfo createFromParcel(final Parcel in) {
			return new ClientInfo(in);
		}

		@Override
		public ClientInfo[] newArray(final int size) {
			return new ClientInfo[size];
		}
	};

	private ClientInfo(final Parcel in) {
		final int[] integers = new int[10];
		final long[] longs = new long[3];

		address = in.readString();
		in.readIntArray(integers);
		in.readLongArray(longs);
		connected = in.readInt() == 1;

		clientID = integers[0];
		samplesGotten = integers[1];
		samplesPut = integers[2];
		eventsGotten = integers[3];
		eventsPut = integers[4];
		lastActivity = integers[5];
		waitEvents = integers[6];
		waitSamples = integers[7];
		error = integers[8];
		diff = integers[9];

		timeLastActivity = longs[0];
		waitTimeout = longs[1];
		time = longs[2];
	}

	public ClientInfo(final String adress, final int clientID, final long time) {
		this.address = adress;
		this.clientID = clientID;
		timeLastActivity = time;
		this.time = time;
	}

	@Override
	public int describeContents() {
		return C.CLIENT_INFO_PARCEL;
	}

	@Override
	public String toString() {
		return address;
	}

	public void update(final ClientInfo update) {
		samplesGotten = update.samplesGotten;
		samplesPut = update.samplesPut;
		eventsGotten = update.eventsGotten;
		eventsPut = update.eventsPut;
		lastActivity = update.lastActivity;
		waitEvents = update.waitEvents;
		waitSamples = update.waitSamples;
		error = update.error;
		timeLastActivity = update.timeLastActivity;
		time = update.time;
		waitTimeout = update.waitTimeout;
		connected = update.connected;
		changed = update.changed;
		diff = update.diff;
	}

	@Override
	public void writeToParcel(final Parcel out, final int flags) {
		// Gathering data
		final int[] integers = new int[] { clientID, samplesGotten, samplesPut,
				eventsGotten, eventsPut, lastActivity, waitEvents, waitSamples,
				error, diff };
		final long[] longs = new long[] { timeLastActivity, waitTimeout, time };

		// Write it to parcel
		out.writeString(address);
		out.writeIntArray(integers);
		out.writeLongArray(longs);
		out.writeInt(connected ? 1 : 0);
	}
}