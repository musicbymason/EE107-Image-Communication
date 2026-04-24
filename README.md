<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    line-height: 1.6;
    color: #333;
  }
  h1 {
    text-align: center;
    color: #2c3e50;
    border-bottom: 2px solid #eee;
    padding-bottom: 0.5em;
    margin-bottom: 0.5em;
  }
  h2 {
    color: #34495e;
    border-bottom: 1px solid #eee;
    padding-bottom: 0.3em;
    margin-top: 1.5em;
  }
  h2:first-of-type {
    text-align: center;
    border: none;
    color: #7f8c8d;
    font-weight: normal;
    margin-top: 0;
  }
  h3, h4, h5 {
    color: #2c3e50;
    margin-top: 1.5em;
  }
  img {
    max-width: 80%;
    height: auto;
    display: block;
    margin: 2em auto;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    border-radius: 6px;
  }
  p {
    text-align: justify;
    margin-bottom: 1em;
  }
  .page-break {
    page-break-before: always;
  }
</style>




# EE107 Mid-Report

## Authors: Jacob Gerson, Asher Milberg, Mason Doshi

---

### Introduction

Our group wanted to use this image for our project.

![Test image](./imgs/macjones.jpg)

<div class="page-break"></div>

#### Q1: Pulse with more bandwidth

Here are the time-domain plots

**Half Sine Wave:**
![](./imgs/Q1/Q1_thalfsine.jpg)

**SRRC Wave:** 
![](./imgs/Q1/Q1_tsrrc.jpg)

And the frequency domain dB plots:

![](./imgs/Q1/Q1_fhalfsine.jpg)

![](./imgs/Q1/Q1_fsrrc.jpg)

The half-sine frequency response uses more bandwidth that the SRRC pulse. The SRRC response has a flat response until ~ 0.5 Hz (which is shown by our rolloff factor alpha), and then drops off. 

In contrast, the half sine response decays very slowly - even at 5 Hz there is only ~ 30 dB drop off whereas at 5 Hz our SRRC response has dropped off by more than 100 dB.

A longer pulse in time means theres a shorter spectrum in the frequency domain and so this makes sense. Since the half-sine is much shorter in time (only one bit period) then its bandwidth is much greater while the SRRC has a much longer pulse in the time domain so its frequency bandwidth is much less.

As alpha decreases, the number of ripples around the peak increase and the bandwidth decreases and as alpha increases, the number of ripples decrease and the bandwidth increases since the transition band cutoff increases. This is because for increasing alphas, there is a larger cutoff so there is more bandwidth required.

Increasing K does not change the bandwidth of the SRRC pulse, since bandwidth is determined by α and T. However, a larger K reduces truncation error by preserving more of the pulse's decaying tails. This results in a frequency response that is closer to the ideal SRRC spectrum. A small K much more greatly truncates the tails, causing energy leakage and ripples visible in the frequency domain.

**SRRC time and frequency domain plots with k = 3:**

![](./imgs/Q1/Q1_tk3.jpg)

![](./imgs/Q1/Q1_fk3.jpg)

**SRRC time and frequency domain plots with k = 6, alpha = 0.1:**

![](./imgs/Q1/Q1_ta0,1.jpg)

![](./imgs/Q1/Q1_fa0,1.jpg)

<div class="page-break"></div>

#### Q2: 10 Random Bits

With a random 10 bit stream, below are the time domain modulations using both the half-sine pulse and SRRC pulse:

![](./imgs/Q2/Q2_mod.jpg)

**Half-Sine Observations:** In the top plot, the half-sine modulated signal appears as distinct, non-overlapping half-periods of a sine wave. Because the half-sine pulse is strictly defined to exist only between $0 \le t \le 1$ bit duration, each pulse begins exactly where the previous one ends. This time-limited nature ensures that, at the transmitter, there is zero overlap between adjacent symbols.

**SRRC Modulation Observation:** In the bottom plot, the SRRC modulated signal looks very different. It looks like a continuous, fluctuating waveform that looks pretty analog. Because a single SRRC pulse spans 12 bit durations ($2K$), the pulses for the 10 consecutive bits overlap and interfere with each other. The amplitude at any given moment is the sum of the main lobe of the current bit and the decaying sidelobes of several surrounding bits.

<div class="page-break"></div>

#### Q3: Spectral Analysis of Modulated Signals

Plot the spectrum of the modulated signal (at the output of the pulse shaping filter) and compare with the pulse spectrum for each pulse. Do the modulated signal spectrum and pulse spectrum have similar shapes? Can you explain the reason for any difference?

Produced below are the spectra of both the modulated signals:

![](./imgs/Q3/Q3_spectra.jpg)

##### Overall Similarities

The modulated signal spectra (for both Half-Sine and SRRC) exhibit the same overall envelope as their corresponding isolated pulses from Question 1. This is because the spectral characteristics of a modulated signal are fundamentally determined by the pulse-shaping filter used. Mathematically, the modulated signal is a convolution of the pulse shape with a random bit sequence; in the frequency domain, this becomes a multiplication of the pulse's spectrum by the spectrum of the bit sequence.

##### Half-Sine Pulse Characteristics

The half-sine modulated spectrum is characterized by a prominent main lobe and a relatively gradual decay in the frequency domain. It features a rounded peak centered at $0$ Hz, which contains the vast majority of the signal's total energy. Because the half-sine pulse has sharp transitions in the time domain where the signal meets the zero-axis, its Fourier transform results in sidebands that decay at a relatively slow rate of $1/f^2$. This lack of a strict cutoff point results in significant high-frequency leakage, where the spectrum exhibits a continuous, slowly diminishing magnitude as frequency increases. This behavior makes the half-sine pulse less efficient for bandwidth-constrained systems, as it can lead to increased interference in adjacent frequency channels.

##### Square Root Raised Cosine (SRRC) Characteristics

The SRRC modulated spectrum is designed for high spectral efficiency and follows strict boundaries defined by its roll-off factor, $\alpha = 0.5$. Unlike the rounded peak of the half-sine, the SRRC exhibits a remarkably flat magnitude response near $0$ Hz, which ensures a more uniform distribution of power across the intended passband. The most defining feature of the SRRC is its extremely sharp cutoff; the magnitude transitions rapidly to a stopband of approximately $-80$ dB near the Nyquist frequency. This makes the SRRC spectrum significantly more "compact" and efficient than the half-sine. By $0.75$ Hz in a normalized system, the energy is almost entirely attenuated, making it an ideal choice for modern communication systems where frequency conservation is a priority.

##### Fluctuations

While the isolated pulses in the previous section produced perfectly smooth spectral curves, the modulated spectra appear jagged and erratic. This difference is caused by the random 10-bit data sequence. The specific arrangement of $+1$ and $-1$ bits creates a unique, high-variance frequency component. When this erratic component is multiplied by the smooth, theoretical frequency response of the pulse shape, it introduces constructive and destructive interference at specific frequencies across the band. Eye Diagrams

<div class="page-break"></div>

#### Q4: Modulated Signal Eye Diagrams

Plots and Comments for the Eye Diagrams for both the Half-Sine and SRRC.

![](./imgs/Q4/Q4_hseye.jpg)

The transmit Half-Sine eye diagram is almost perfectly overlayed on top of each other. It is shifted slightly to the right, but this makes sense as we took one slice of data off the end so the plots were lined up with each other. This eye is wide, which follows the characteristics of the half-sine modulation. In the half-sine the signal period for each bit is entirely seperated and there is no overflow onto the following period from the current bit being transmitted. Since there is little overflow this creates a wide open, and thin signaled, eye. 

![](./imgs/Q4/Q4_srrceye.jpg)

The Square Root Raised Cosine (SRRC) eye diagram appears somewhat closed at the transmitter output because an individual SRRC pulse has trailing noise that leaks beyond the bit duration. This does not satisfy Nyquist’s First Criterion for zero Inter-Symbol Interference (ISI). The SRRC’s tails do not cross zero at every integer multiple of the bit period ($T$), causing the energy from adjacent bits to leak into the current sampling instant. 

<div class="page-break"></div>

#### Q5: Frequency and Impulse Response of the Channel

![](./imgs/Q5/Q5_Channel_Responses.jpg)

#### Q6: Eye Diagram of Channel Output

![](./imgs/Q6/After_Channel_Eye_HS.jpg)

![](./imgs/Q6/After_Channel_Eye_SRRC.jpg)

The eye diagrams at the channel output exhibit significant closure compared to the original transmitted signals, a direct result of Inter-Symbol Interference (ISI) introduced by the channel’s impulse response. Because the channel acts as a non-ideal filter, it causes the energy of each individual pulse to spread into adjacent bit periods, destroying the zero-crossing properties of the original Half-Sine and SRRC shapes.

#### Q7: Noisy Eye Diagram of Channel Output

![](./imgs/Q7/Combined_Noise_Analysis.jpg)

The addition of Gaussian noise introduces random vertical displacement to the signal, directly attacking the noise margin of the eye diagram. At lower noise powers ($\sigma^2$), the eye remains identifiable but fuzzy, indicating a functional but worsening communication link. However, as $\sigma$ increases, the random fluctuations eventually overwhelm the signal's structural transitions (ISI), causing the eye to close completely. In the high-noise scenarios, the diagrams become indistinguishable from one another, as the signal is ruined by the noise introduced from the Gaussian distribution. This visualization demonstrates the threshold at which a receiver would fail to differentiate between a '1' and a '0', leading to a significant spike in the bit error rate.

#### Q8: Matched Filter Output - Impulse and Frequency Response Graphs

![](./imgs/Q8/matched.jpg)

The impulse and frequency reeponses in Q1 represent the ideal pulse shapes and their spectrums. 

The below Q8 plots correspond to the matched filter output. Comparing against the ideal signal plots from Q1, it's clear that the signals are noisy and barely resemble the original pulses. The frequency response graphs are also noisy and have some fluctuations due to the channel ISI and additive random noise. However, the spectral shape is still a lowpass and the SRRC signal is still bandlimited than the half since, so we maintain that the right data is being sent through, albeit with many pertubations. 

#### Q9: Matched Filter Output - Eye Diagrams for 1 & 2 Bit Durations

**Matched Filter Eye Diagram - 1 Bit Duration**
![](./imgs/Q9/Matched_Filter_Eyes_1bit.jpg)

**Matched Filter Eye Diagram - 2 Bit Duration**
![](./imgs/Q9/Matched_Filter_Eyes.jpg)


For the half sine, we want to sample at 0.5 seconds. (Max Eye Opening).
For the SRRC we want to sample at 0.3 seconds. (Max Eye Opening)

#### Q10: The Zero-Forcing (ZF) Equalizer

We will implement the zero-forcing filter by computing the frequency response of the channel and then create an inverse filter by taking the reciprocal of the channel response in the frequency domain. Then it will be converted back to the time domain to get the impulse response of the ZF equalizer. The signal is convolved with the equalizer which will ideally cancel out channel distortion.

Here are both the impulse and frequency responses of the zero-forcing filter:

![](./imgs/Q10/Q10.jpg)


The frequency response of the zero forcing equalizer has large spikes at frequencies where the channel amplifies the signal. The impulse response is very long and decays very slowly. The ZF equalizer is stable because H(f) is never 0, so 1/H(f) is finite at all frequencies. 

The channel's inverse is not always guaranteed to be stable - at certain discrete samples the channel response is 0 and results in an infinite response from the Zero-Forcing channel. 

#### Q11: Zero-Forcing (ZF) Equalizer Eye Diagrams

The following unified figure shows the eye diagrams for both Half-Sine (HS) and SRRC pulse shapes after Zero-Forcing equalization across different noise levels ($\sigma^2 = 0, 0.005, 0.02$):

![](./imgs/Q11/ZF_Eyes_Combined.jpg)

These graphs show exactly what is expected of the zero forcing (ZF) equalizer. With little noise we can see the effects clearly for both pulse shapes, where the magnitudes stay between -1 and 1. However, once noise is added the magnitudes shoot way beyond these values as the equalizer cannot account for these variables.

**Zero-Forcing Time Domain Output (10-bit stream):**

![](./imgs/Q11/ZF_time_10bit.jpg)

These results are an updated graph to show the progess of our information along this communication system's path. 

#### Q12 The MMSE Equalizer 

To compute the MMSE filter, we did most of the math in the frequency domain. By utilizing the FFT and the frequency math to get the equation for the MMSE. Then, by taking the ifft of this frequency response to get the impulse response of the filter. Finally by convolving this with the output of the channel to get the final output of the filter.

![](./imgs/Q12/MMSE_freq.jpg)

The Zero-Forcing (ZF) equalizer tries to perfectly invert the channel, but this backfires by creating "ringing" and long messy tails in the impulse response. Because it ignores noise, it amplifies interference at frequencies where the channel is weak, leading to a cluttered output.

The MMSE equalizer is much cleaner because it balances fixing the channel with suppressing noise. Its impulse response shows only the essential spikes—one to capture the main signal and another to cancel the primary echo—without the extra "junk." This makes the MMSE eye diagrams stay significantly more open and stable as the noise increases compared to the ZF results.

#### Q13: The MMSE Equalizer Eye Diagrams

![](./imgs/Q13/MMSE_eye.jpg)

These graphs give an expected output for the filter. The outputs are normalized and with an increase in noise, the output of the filter does perform better in producing a reconizable eye diagram as compared to the zero forcing equalizer. However, there is still significant noise.

**MMSE Time Domain Output (10-bit stream):**

![](./imgs/Q13/MMSE_time_10bit.jpg)

While significant noise still compromises the results to where it is incredibly hard to see. The MMSE does a better job at clearing up the noise.

<div class="page-break"></div>

#### Q14: Final Image Transmission Comparison

Below is the **grayscale reference image** that is actually processed and transmitted through the system (after 8x8 DCT block processing and bit conversion):

![Grayscale Reference](./imgs/Q14/Reference_Gray.jpg)

To comprehensively evaluate our system, we simulated the transmission of the full image across all combinations of pulse shaping (Half-Sine vs. SRRC), equalization (Zero-Forcing vs. MMSE), and noise levels ($\sigma^2 \in \{0.00, 0.005, 0.02, 0.05\}$).

The result grid below showcases how each component contributes to the final image quality:

![](./imgs/Q14/Final_Result.jpg)

##### Key Observations:

Overall, the differences between the two filters are not as great as we were initially expecting, but the SRRC seems marginally better, especially when the noise levels are much lower. However, at higher noise levels, the half-sine filter seems to do better. This seems odd since in class, we learned in class that SRRC is better by a lot, so these results seem very surprising. In terms of the image quality as a whole, we suspect much of the poor quality is the result of a lot of ISI, which is what we were expecting. 

<div class="page-break"></div>

#### Q15: Critical SNR Thresholds

The critical SNR threshold is the point where the Bit Error Rate (BER) becomes high enough to visibly degrade the reconstructed image (typically around $10^{-2}$ or $10^{-3}$).

- **Zero-Forcing (ZF) Equalizer:** Has a **higher critical SNR** (approx. 18-20 dB). Because ZF inverts the channel, it significantly amplifies noise at frequencies where the channel response is weak. This "noise enhancement" causes the system to fail quickly as noise increases.
- **MMSE Equalizer:** Has a **lower critical SNR** (approx. 12-15 dB). By balancing channel inversion with noise suppression, the MMSE equalizer prevents extreme noise amplification, maintaining image integrity at much lower signal-to-noise ratios.

#### Q16: Performance on Different Images

When testing the system with different images (e.g., comparing our reference image with standard test images like *cameraman*), the fundamental performance of the equalizers remains consistent. While busy images with high-frequency textures might "mask" bit errors better than smooth, low-frequency images, the underlying Bit Error Rate is independent of the image content and depends solely on the modulation, channel, and noise parameters.

#### Q17: Nyquist Criterion and Zero ISI

PLOT THE OUTPUT OF THE MATCHED FILTER FOR BOTH PULSES FIRST:

Again, from Q9, here is the eye diagram of both pulses across noise environments: 

**Matched Filter Output Eye Diagram**

![](./imgs/Q9/Matched_Filter_Eyes.jpg)

For either output to satisfy the Nyquist criterion, the output eye diagrams would need to exhibit complete convergence at our determined sampling times for both pulses. In neither case is the Nyquist criterion for zero ISI at those sampling times met.

However, the combination of the half-sine pulse output of the matched filter and the MMSE equalizer produces an output that does satisfy the Nyquist criterion. Those diagrams, originally shown in Q13, show the elimination of ISI at the ideal sampling point of the random bit stream.

![](./imgs/Q13/MMSE_eye.jpg)

Ideally, the output of the image data reflects the half-pulse used in conjuction with the MMSE equalizer being the best option for transmission when no noise is present in the system. However, it's likely that this advantage is drowned out by the properties demonstrated by the SRRC pulse at higher noise levels. 

TODO ONCE BIT ERROR IS FIXED MAKE THIS LANGUAGE STRONGER

#### Q18: Error Performance at Equal Energy

We expect that the error performance is roughly the same between the two pulses. Since both pulses have the same energy, they sould have the same SNR at the reciever for the same noise power. Although, we would expect the ISI and filtering to be different between the two. The SRRC will have the response behave like a raised cosine pulse which reduces ISI at the sampling points. The half-sine pulse isn't meant to satisfy the Nyquist zero-ISI condition after the matched filter so the SRRC should have better error performance. 

We used the images that were produced from 14. At σ^2 = 0.005 (with all other variables being kept constant),, looking at the half sine and the SRRC with the MMSE, the results are pretty similar, but the half sine looks marginially better. The eyes and outline of Mac Jones is much more pronounced in the half sine MMSE output while the SRRC output is more obscured. So, at this noise level, the half sine is more robust to noise under these conditions., even when both pulses have the same energy. THe differences could be because of how the channel, matched filter, and MMSE affect the two pulses. 

#### Q19: Bandwidth and Pulse Length

- **Bandwidth:** The half-sine pulse has a much larger bandwidth than the SRRC pulse. This is due to the sharp transitions in its time-domain shape, which correspond to slow $1/f^2$ decay in the frequency domain.



- **Pulse Length:** The length of the SRRC pulse ($2K$ bit durations) is a trade-off. Increasing $K$ allows for a more ideal, "brick-wall" like frequency response with less truncation error, but it increases system latency and necessitates more complex equalization as each bit interferes with more of its neighbors.


#### Q20: Conclusion on Pulse Shaping

Overall, we have found that the SRRC pulse is worse in terms of ISI which is surprising because it contrasts with what we were taught in class.  

#### Q21: Performance under New Channels

We tested the system under two additional wireless channel models:
1.  **Outdoor Channel ($h_1$):** Characterized by long delays (up to 25 bits), representing reflections from distant buildings. This channel has a higher total **power gain** ($\sum |h[n]|^2 \approx 1.745$), but the severe delay spread makes equalization significantly more challenging.
![](./imgs/Q21/Recovered_Outdoor.jpg)


2.  **Indoor Channel ($h_2$):** Characterized by shorter, rapidly decaying echoes. While it has a lower power gain ($\approx 1.234$), its performance is generally better because the ISI is "short-lived" and more easily corrected by the MMSE equalizer.
![](./imgs/Q21/Recovered_Indoor.jpg)



