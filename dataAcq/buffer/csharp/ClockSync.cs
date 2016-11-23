using System.Collections;
using System.Diagnostics;

namespace FieldTrip.Buffer
{
	public class ClockSync
	{
		Stopwatch stopWatch = null;
		double S0, T0;
		// starting samples, time
		public double Tlast = -1000, Slast = -1000;
		//last time at which the sync was updated, needed to compute accuracy?
		public double N = -1;
		// number points
		double sS = 0, sT = 0;
		// sum samples, time
		double sS2 = 0, sST = 0, sT2 = 0;
		// sum product samples time
		public double m, b;
		// fit, scale and offset
		double alpha, hl;
		// learning rate, halflife
		double sampErr = 0;
		// running estimate of the est-true sample error
		double minUpdateTime = 50;
		// only update if at least 50ms apart, prevent rounding errors
		double weightLim = 0;

		public ClockSync()
			: this(.95)
		{
		}
		//N.B. half-life = log(.5)/log(alpha) .95=13 steps
		public ClockSync(double alpha)
		{ 
			this.alpha = alpha; 
			stopWatch = Stopwatch.StartNew();
			reset();
		}

		public ClockSync(double nSamples, double time, double alpha)
			: this(alpha)
		{
			updateClock(nSamples, time);
		}

		public void reset()
		{
			N = -1;
			S0 = 0;
			T0 = 0;
			sS = 0;
			sT = 0;
			sS2 = 0;
			sST = 0;
			sT2 = 0;
			Tlast = -10000;
			Slast = -10000;
			sampErr = 10000;
		}

		public double getTime()
		{ // current time in milliseconds
			return ((double)stopWatch.ElapsedTicks / (double)(Stopwatch.Frequency / 1000));
		}

		public void updateClock(double S)
		{
			updateClock(S, getTime());
		}

		public void updateClock(double S, double T)
		{
			//System.Console.WriteLine("Before: S,T=" + S + "," + T + "," + " m,b=" + m + "," + b);
			if (S < Slast || T < Tlast) {
				reset();
			} // Buffer restart detected, so reset
			if (N <= 0) { // first call with actual data, record the start points
				N = 0;
				S0 = S;
				T0 = T;
				Tlast = T;
				Slast = S;
			} else if (S == Slast || T == Tlast || T < Tlast + minUpdateTime) {
				//System.Console.WriteLine("Too soon! S=" + S + " Slast=" + Slast + " T=" + T + " Tlast=" + Tlast);
				// sanity check inputs and ignore if too close in time or sample number 
				// -> would lead to infinite gradients
				return;
			}
			// Update the sample error statistics
			double estErr = System.Math.Abs(getSamp(T) - S); 
			if (N > 1 && N < weightLim) { // reset in the initial phase
				sampErr = estErr;
			} else { // running average after predictions are reliable
				sampErr = sampErr * alpha + (1 - alpha) * estErr;
			}
			// BODGE: this should really the be integerated weight
			double wght = System.Math.Pow(alpha, ((double)(T - Tlast)) / 1000.0); // weight based on time since last update
			Tlast = T;
			Slast = S;
			// subtract the 0-point
			S = S - S0;
			T = T - T0;
			// update the summary statistics
			N = alpha * N + 1;
			sS = alpha * sS + S;
			sT = alpha * sT + T;
			sS2 = alpha * sS2 + S * S;
			sST = alpha * sST + S * T;
			sT2 = alpha * sT2 + T * T;
			// update the fit parameters
			double Tvar = sT2 - sT * sT / N;
			double STvar = sST - sS * sT / N;
			if (N > 1.0 && Tvar > STvar * 1e-10) { // only if have good enough condition number (>1e-10)
				m = STvar / Tvar; // NaN if origin and 1 point only due to centering
				b = sS / N + S0 - m * (sT / N + T0);
			} else if (N > 0.0 && T > 0.0) { // fit straigt line from origin to this cluster
				m = sS / sT;
				b = S0 - m * T0;
			} else { // default to just use the initial point
				m = 0;
				b = S0;
			}
			//System.Console.WriteLine("Update: S,T=" + S + "," + T + "," + " wght=" + wght + " m,b=" + m + "," + b);
		}

		public long getSamp()
		{
			return getSamp(getTime());
		}

		public long getSamp(double time)
		{ 
			return (long)(N > 0 ? (m * time + b) : Slast); //If not enough data yet, just return last seen #samp
		}
		// N.B. the max weight is: \sum alpha.^(i) = 1/(1-alpha)
		//      and the weight of 1 half-lifes worth of data is : (1-alpha.^(hl))/(1-alpha);
		public long getSampErr()
		{
			//System.Console.WriteLine(" N = " + N + " weightLim = " + weightLim + " sampErr = " + sampErr);
			//BODGE:time since last update in samples
			return (Tlast > 0 && N > 1) ? ((long)sampErr) : 100000;
		}
	}
}
