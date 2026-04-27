# EE107 Final Report

## Authors: Jacob Gerson, Asher Milberg, Mason Doshi

---

### Introduction

Our group wanted to use this image for our project.

![Test image](./imgs/macjones.jpg)

<div class="page-break"></div>

#### Q1: Pulse with more bandwidth

Here are the time-domain plots

**Half Sine Wave:**
![](./imgs/Q1/Q1_tsrrc.jpg)

**SRRC Wave:** 
![](./imgs/Q1/Q1_tk3.jpg)

And the frequency domain dB plots:

![](./imgs/Q1/Q1_fsrrc.jpg)

![](./imgs/Q1/Q1_fa0,1.jpg)

The half-sine frequency response uses more bandwidth that the SRRC pulse. The SRRC response has a flat response until ~ 0.5 Hz (which is shown by our rolloff factor alpha), and then drops off. 

In contrast, the half sine response decays very slowly - even at 5 Hz there is only ~ 30 dB drop off whereas at 5 Hz our SRRC response has dropped off by more than 100 dB.

A longer pulse in time means theres a shorter spectrum in the frequency domain, so this makes sense. Since the half-sine is much shorter in time (only one bit period) then its bandwidth is much greater. The SRRC, meanwhile, has a much longer pulse in the time domain so its frequency bandwidth is much less.

As alpha decreases, the number of ripples around the peak increase and the bandwidth decreases. As alpha increases, the number of ripples decrease and the bandwidth increases since the transition band cutoff increases. This is because for increasing alphas, there is a larger cutoff so more bandwidth required.

Increasing K does not change the bandwidth of the SRRC pulse, since bandwidth is determined by α and T. However, a larger K reduces truncation error by preserving more of the pulse's decaying tails. This results in a frequency response that is closer to the ideal SRRC spectrum. A small K truncates the tails more, causing energy leakage and ripples visible in the frequency domain.

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

**Half-Sine Observations:** In the top plot, the half-sine modulated signal is distinct, non-overlapping half-periods of a sine wave. Because the half-sine pulse is strictly defined to exist only between $0 \le t \le 1$ bit duration, each pulse begins exactly where the previous one ends. The pulse being time-limited at the transmitter means that there is zero overlap between adjacent symbols.

**SRRC Modulation Observation:** In the bottom plot, the SRRC modulated signal looks very different. It looks like a continuous, fluctuating waveform that looks pretty analog. Because a single SRRC pulse spans 12 bit durations ($2K$), the pulses for the 10 consecutive bits overlap and interfere with each other. The amplitude at any given moment is the sum of the main lobe of the current bit and the decaying sidelobes of several surrounding bits.

<div class="page-break"></div>

#### Q3: Spectral Analysis of Modulated Signals

Below are the spectra of both the modulated signals:

![](./imgs/Q3/Q3_spectra.jpg)

##### Overall Similarities

The modulated signal spectra (for both half sine and SRRC) have the same overall envelope as their corresponding isolated pulses from Question 1. This is because the spectral characteristics of a modulated signal are determined by the pulse-shaping filter used. The modulated signal is a convolution of the pulse shape with a random bit sequence; in the frequency domain, this becomes a multiplication of the pulse's spectrum by the spectrum of the bit sequence.

##### Half-Sine Pulse Characteristics

The half-sine modulated spectrum is characterized by a main lobe and a relatively gradual decay in the frequency domain. It features a rounded peak centered at $0$ Hz, which contains the majority of the signal's total energy. Because the half-sine pulse has sharp transitions in the time domain where the signal meets the zero-axis, its Fourier transform results in sidebands that decay at a relatively slow rate of $1/f^2$. This lack of a strict cutoff point means that there is a lot of high-frequency leakage, where the spectrum has a continuous, slowly diminishing magnitude as frequency increases. This behavior makes the half-sine pulse less efficient for bandwidth-constrained systems, as it can lead to increased interference in adjacent frequency channels.

##### Square Root Raised Cosine (SRRC) Characteristics

The SRRC modulated spectrum has high spectral efficiency and its boundaries are defined by its roll-off factor, $\alpha = 0.5$. Unlike the rounded peak of the half-sine, the SRRC has a flat magnitude response near $0$ Hz, which makes sure it has a uniform distribution of power across the intended passband. The most defining feature of the SRRC is its sharp cutoff; the magnitude transitions quickly to a stopband of approximately $-80$ dB near the Nyquist frequency. This makes the SRRC spectrum more "compact" and efficient than the half-sine. By $0.75$ Hz in a normalized system, the energy is almost entirely attenuated.

##### Fluctuations

While the isolated pulses in the previous section produced smooth spectral curves, the modulated spectra appear jagged and erratic. This difference is caused by the random 10-bit data sequence. The arrangement of $+1$ and $-1$ bits has a unique, high-variance frequency component. When this component is multiplied by the smooth, theoretical frequency response of the pulse shape, it introduces constructive and destructive interference at specific frequencies across the band. 

<div class="page-break"></div>

#### Q4: Modulated Signal Eye Diagrams

![](./imgs/Q4/Q4_hseye.jpg)

The half sine eye diagram is almost perfectly overlayed on top of each other. It is shifted slightly to the right, but this makes sense as we took one slice of data off the end so the plots were lined up with each other. This eye is wide, which follows the characteristics of the half-sine modulation. In the half-sine the signal period for each bit is entirely seperated and there is no overflow onto the following period from the current bit being transmitted. Since there is little overflow, this creates a wide open, and thin signaled, eye. 

![](./imgs/Q4/Q4_srrceye.jpg)

The SRRC eye diagram looks somewhat closed at the transmitter output because an individual SRRC pulse has trailing noise that leaks beyond the bit duration. This does not satisfy Nyquist’s First Criterion for zero ISI. The SRRC’s tails do not cross zero at every integer multiple of the bit period ($T$), causing the energy from adjacent bits to leak into the current sampling instant. 

<div class="page-break"></div>

#### Q5: Frequency and Impulse Response of the Channel

![](./imgs/Q5/Q5_Channel_Responses.jpg)

#### Q6: Eye Diagram of Channel Output

![](./imgs/Q6/After_Channel_Eye_HS.jpg)

![](./imgs/Q6/After_Channel_Eye_SRRC.jpg)

The eye diagrams at the channel output is more closed compared to the original transmitted signals, a  result of ISI introduced by the channel's impulse response. Because the channel acts as a non-ideal filter, it causes the energy of each individual pulse to spread into adjacent bit periods, destroying the zero-crossing properties of the original half sine and SRRC shapes.

#### Q7: Noisy Eye Diagram of Channel Output

![](./imgs/Q7/Combined_Noise_Analysis.jpg)

The addition of Gaussian noise introduces random vertical displacement to the signal, reducing the noise margin of the eye diagram. At lower noise powers ($\sigma^2$), the eye looks identifiable but a little fuzzy, meaning there is probably worsening communication link. However, as $\sigma$ increases, the random fluctuations eventually makes the eye close completely. This visualization shows the threshold at which a receiver would fail to differentiate between a '1' and a '0', leading to a spike in the bit error rate.

#### Q8: Matched Filter Output - Impulse and Frequency Response Graphs

![](./imgs/Q8/matched.jpg)

The impulse and frequency reeponses in Q1 show the ideal pulse shapes and their spectrums. 

The above Q8 plots are the matched filter output. Comparing against the ideal signal plots from Q1, the signals are noisy and barely resemble the original pulses. The frequency response graphs are also noisy and have some fluctuations due to the channel ISI and the additive random noise. However, the spectral shape is still a lowpass and the SRRC signal is still bandlimited than the half since, so we know that the right data is being sent through, albeit with many deviations. 

#### Q9: Matched Filter Output - Eye Diagrams for 1 & 2 Bit Durations

**Matched Filter Eye Diagram - 1 Bit Duration**
![](./imgs/Q9/Matched_Filter_Eyes_1bit.jpg)

**Matched Filter Eye Diagram - 2 Bit Duration**
![](./imgs/Q9/Matched_Filter_Eyes.jpg)


For the half sine, we want to sample at 0.5 seconds which is where the eye opens the most.
For the SRRC we want to sample at 0.3 seconds which is where the eye opens the most.

With set bit periods of 1 second, these time markers also represent the percent of the total taken samples where the ideal sampling point would lie.  

#### Q10: The Zero-Forcing (ZF) Equalizer

We will implement the zero-forcing filter by computing the frequency response of the channel and then creating an inverse filter by taking the reciprocal of the channel response in the frequency domain. Then it will be converted back to the time domain to get the impulse response of the ZF equalizer. The signal is convolved with the equalizer which will ideally cancel out channel distortion.

Here are both the impulse and frequency responses of the zero-forcing filter:

![](./imgs/Q10/Q10.jpg)

The frequency response of the zero forcing equalizer has large spikes at 4.25 Hz, 4.75 Hz, 5.25 Hz, 5.75 Hz and so on. This is where the channel amplifies the signal. The impulse response is very long and decays very slowly. The ZF equalizer is stable because H(f) is never 0, so 1/H(f) is finite at all frequencies. 

The channel's inverse is not always guaranteed to be stable - at certain discrete samples the channel response is 0 and results in an infinite response from the Zero-Forcing channel. 

#### Q11: Zero-Forcing (ZF) Equalizer Eye Diagrams

The following unified figure shows the eye diagrams for both half sine and SRRC pulse shapes after Zero-Forcing equalization across different noise levels ($\sigma^2 = 0, 0.005, 0.02$):

![](./imgs/Q11/ZF_Eyes_Combined.jpg)

These graphs show exactly what is expected of the zero forcing (ZF) equalizer. With little noise, we can see the effects for both pulse shapes, where the magnitudes stay between -1 and 1. However, once noise is added, the magnitudes shoot way beyond these values as the equalizer cannot account for these variables.

**Zero-Forcing Time Domain Output (10-bit stream):**

![](./imgs/Q11/ZF_time_10bit.jpg)

These results are an updated graph to show the progess of our information along the communication system's path. 

#### Q12 The MMSE Equalizer 

To compute the MMSE filter, we did most of the math in the frequency domain. By utilizing the FFT and the frequency math to get the equation for the MMSE. Then, we took the ifft of the frequency response to get the impulse response of the filter. Finally, to get the final output of the filter, we convolved the impulse response of the filter with the output of the channel to get the final output of the filter.

![](./imgs/Q12/MMSE_freq.jpg)

The Zero-Forcing equalizer tries to perfectly invert the channel, but it doesn't go so well because it creates echoes and long messy tails in the impulse response. Because it ignores noise, it amplifies interference at frequencies where the channel is weak, leading to a cluttered output.

The MMSE equalizer is much better because it fixes the channel and supresses noise. Its impulse response shows only the essential spikes—one to capture the main signal and another to cancel the primary echo (at 33 samples). So, the MMSE eye diagrams is more open and stable as the noise increases compared to the ZF results.

#### Q13: The MMSE Equalizer Eye Diagrams  

![](./imgs/Q13/MMSE_eye.jpg)

At σ² = 0, both pulse shapes have an open eye, with the half-sine appearing more tightly clustered while the SRRC is more spread out due to its longer pulse duration and overlap. Even in the noiseless case, the SRRC traces are less compact, which means there's more residual ISI, but both still have a visible sampling point. As noise increases to σ² = 0.005 and 0.020, the eye openings begin to close for both pulses, but the traces remain bounded, indicating that the MMSE equalizer is limiting noise amplification.

**MMSE Time Domain Output (10-bit stream):**

![](./imgs/Q13/MMSE_time_10bit.jpg)

This behavior is consistent in the aligned time-domain outputs. At σ² = 0, both pulse shapes track the transmitted symbols, with separation between ±1 levels. As noise increases, the signals become more distorted, but are still stable and follow the overall symbol transitions. Even at σ² = 0.020, although the signal is noisy and it's still hard to determine what's a 0 and a 1, the waveform structure is still there, showing that the MMSE equalizer trades off perfect channel inversion for improved robustness to noise.

<div class="page-break"></div>

#### Q14: Final Image Transmission Comparison

Below is the **grayscale reference image** that is processed and transmitted through the system (after 8x8 DCT block processing and bit conversion):

![Grayscale Reference](./imgs/Q14/Reference_Gray.jpg)

To evaluate our system, we simulated the transmission of the full image across all combinations of pulse shaping (half sine vs. SRRC), equalization (Zero-Forcing vs. MMSE), and noise levels ($\sigma^2 \in \{0.00, 0.005, 0.02, 0.05\}$).

The result grid below showcases how each component contributes to the final image quality:

![](./imgs/Q14/Final_Result.jpg)

##### Key Observations:

Overall, MMSE equalizer has a clearer and much better performance as the noise level increases throughout the trials. With lower noise there is little difference (if any the MMSE is worse), however the special effects of the MMSE is shown when the noise levels are increased and there are less bit errors. For difference in pulses there seems to be little if any difference in the behavoir between the pulse shapes. The outcome of each image is almost entirely the same.

<div class="page-break"></div>

#### Q15: Critical SNR Thresholds

Half Sine: The critical SNR threshold is the point where the Bit Error Rate (BER) becomes high enough to visibly degrade the reconstructed image is when the noise variance = 0.005 . Since we have normalized the power of the signal to be 1, the SNR = Psig/Pnoise = 1/0.005. In dB this equates to 23dB.

SRRC: The critical SNR threshold is the point where the Bit Error Rate (BER) becomes high enough to visibly degrade the reconstructed image is when the noise variance = 0.05 . Since we have normalized the power of the signal to be 1, the SNR = Psig/Pnoise = 1/0.05. In dB this equates to 13dB.

Here is the BER vs SNR graph for the ZF and MMSE equalizers:

![](./imgs/Q15/Q15_BER_Curves.jpg)

#### Q16: Performance on Different Images

Below are the results for doing the same analysis and modulation on a picture of Raven's QB Lamar Jackson:

![](./imgs/Q16/Final_Result_lamar.jpg)

From the image above we can see that the effects on the new image is almost identical as to the original image of Mac Jones. The difference between the two pulses and the two different equalizers are the same variance as it was in the first test of Mac. We can see that as the noise increased the MMSE equalizer has a vastly better effect on handling the noise and having a much clearer output. As for the pulse shape, the results (just like the original image) are almost identical to each other. It seems that pulse shape has no difference when simulated from our simulation results.

#### Q17: Nyquist Criterion and Zero ISI


Again, from Q9, here is the eye diagram of both pulses across noise environments: 

**Matched Filter Output Eye Diagram**

![](./imgs/Q9/Matched_Filter_Eyes.jpg)

For either output to satisfy the Nyquist criterion, the output eye diagrams would need to exhibit complete convergence at our determined sampling times for both pulses. In neither case is the Nyquist criterion for zero ISI at those sampling times met.

However, the combination of the half-sine pulse output of the matched filter and the MMSE equalizer produces an output that does satisfy the Nyquist criterion. Those diagrams, originally shown in Q13, show the elimination of ISI at the ideal sampling point of the random bit stream.

![](./imgs/Q13/MMSE_eye.jpg)

Ideally, the output of the image data reflects the half-pulse used in conjuction with the MMSE equalizer being the best option for transmission when no noise is present in the system. However, it's likely that this advantageous quality is drowned out by the properties demonstrated by the SRRC pulse at higher noise levels. 

#### Q18: Error Performance at Equal Energy

We expected that the error performance is roughly the same between the two pulses. Since both pulses have the same energy, they should have the same SNR at the receiver for the same noise power. However, we would still expect differences in ISI and filtering between the two. The SRRC pulse is designed so that, after matched filtering, the response behaves like a raised cosine pulse, which reduces ISI at the sampling points. The half-sine pulse is not designed to satisfy the Nyquist zero-ISI condition after the matched filter, so we would expect the SRRC to have better error performance.

We used the images that were produced for Q14. At a σ^2 of 0.005 (with all other variables kept constant) and looking at the MMSE equlizer results, we can see that the SRRC pulse does much better. The images are very similar but there is just slightly less noise in the SRRC output. Even though both pulses have the same energy, the SRRC is more robust to noise.

#### Q19: Bandwidth and Pulse Length

From the frequency response plots in question 1 and the modulated signal spectra in question 3, we can see that the half sine pulse has a higher bandiwth with many sidelobes being far beyond the main lobe. The SRRC pulse, however, has its sidelobes closer to the main lobe and has a smaller bandwidth. The half sine pulse only happens for one period so since its short in the time domain, its extends a lot in the frequency domain. The SRRC is wider in time and more compact in the frequency domain due to it spanning more time intervals of each transmitted symbol. The SRRC is more bandwidth efficient because of the smaller bandiwdth and because it reduces the components that are out of the frequency range we are looking at. This is good since the bandwidth is limited in our case. But, the longer duration of the SRRC causes more symbol overlap which could lead to  higher ISI.

#### Q20: Conclusion on Pulse Shaping
Overall, as expected, given what we learned in class, the SRRC outperforms the half sine pulse in image reconstruction, although it's pretty close. The SRRC + MMSE gave the best results. The main drawbacks of the SRRC (as discussed in question 19) is that it is longer in time. The SRRC pulse spans across many bit durations so it causes more pulse overlap at the transmitter and makes sampling more sensitive. It is also nore complex to implement than the half-sine. But, the SRRC gives better bandwidth control and is more robust to noise (emphasesized by our results). 

#### Q21: Performance Under New Channels
The communication system did not work seamlessly when we plugged in the new channels. The image is barely recognizable for both channels but some information is still there. There is a lot of noise in both images and visible reconstruction errors.

The indoor channel performed slightly better than the outdoor channel. In the indoor channel output, the face and body outlines are more defined and you can tell that the shirt the person is wearing is a jersey. This makes snese since the outdorr channel has logner delayed echoes which causes more ISI and makes equalization harder. 

The power gain of a channel is the energy of its impulse response:

$$
\|h\|^2 = \sum_{n} |h[n]|^2
$$

### Outdoor Channel

$$
\|h_1\|^2 = 0.5^2 + 1^2 + 0.63^2 + 0.25^2 + 0.16^2 + 0.1^2
$$

$$
= 0.25 + 1 + 0.3969 + 0.0625 + 0.0256 + 0.01
$$

$$
= 1.745
$$

![](./imgs/Q21/Recovered_Outdoor.jpg)

### Indoor Channel

$$
\|h_2\|^2 = 1^2 + 0.4365^2 + 0.1905^2 + 0.0832^2 + 0.0158^2 + 0.003^2
$$

$$
= 1 + 0.19053225 + 0.03629025 + 0.00692224 + 0.00024964 + 0.000009
$$

$$
\approx 1.234
$$

![](./imgs/Q21/Recovered_Indoor.jpg)

The outdoor channel has a higher power gain. However, the autdoor channel has worse image quality because its energy is spread across longer delays which creates more ISI, while the indoor channel's energy is concetrated around the concise delays so the recovered image is better.

