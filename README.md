# EE107 Midterm Report

## Authors: Jacob Gerson, Asher Milberg, Mason Doshi

### Introduction
The EE107 final project tasks students with ....

![Test image](./imgs/system_diagram.png) 


### Phase 1: Image Preprocessing

Preprocessing requires the following steps:

1. Converting image to desired data type in Matlab (double)
2. Taking DCT (Discrete Cosine Transform) to get frequency composition of the image 
3. Quantizing our frequency coefficient values into discrete 8x8 DCT blocks to be transmitted


Our group landed on the following 1280 x 720 image to process :

![Test image](./imgs/macjones.jpg)


### Phase 2: Conversion to Bit. Streeam

### Phase 3: Modulation (Questions 1-4)


TODO FINISH Q1
#### Q1: Below are the time domain plots for both the Half-sine pulse and SRRC (Square Root Raised Cosine):

![](./imgs/Q1/Q1_thalfsine.jpg)

![](./imgs/Q1/Q1_tsrrc.jpg)

And the frequency domain dB plots:

![](./imgs/Q1/Q1_fhalfsine.jpg)

![](./imgs/Q1/Q1_fsrrc.jpg)

It's clear to see qualitatively that the half-sine frequency response uses significantly more bandwidth that the SRRC pulse. The SRRC response has a flat response until ~ 0.5 Hz (which we see as clearly defined by our rolloff factor alpha), and then drops off sharply 

In contract, the half sine response decays very slowly - even at 5 Hz there is only ~ 30 dB drop off whereas at 5 Hz our SRRC response has dropped off by more than 100 dB.

This result is the effect of the time-frequency scaling property. Since we aggresively truncate the half-sine pulse in the time domain 0 t < 1, there is a sharp transition that requires high frequencies to reconstruct in the frequency domain. The SRRC pulse, however, is allowed to span 2*K bit durations. The smoother tapering of this frequency response avoids any sharp edges in the time domain, which allows for a much more tightly confined frequency band. 

This informs how we analyze the impact of our bit truncation factor K. Higher values of K enable the frequency response to approach an ideal sharp cutoff. Additionally, we can also see how adjusting the roll-off factor alpha dictates the sharpness of the filter. Lower roll-off factors will sharpen, and save bandwidth in the frequency domain.

Let's confirm this. The above frequency response of the SRRC pulse uses a K = 6, alpha = 0.5. Below is the time and frequency plots using K = 3, alpha = 0.5:

![](./imgs/Q1/Q1_tk3.jpg)

![](./imgs/Q1/Q1_fk3.jpg)

The lower 

and here is k = 6, alpha = 0.1:

![](./imgs/Q1/Q1_ta0,1.jpg)

![](./imgs/Q1/Q1_fa0,1.jpg)

TODO COMMENTS ON BOTH ABOVE



#### Q2: For a random 10 bits (1, -1), here is the p

With a random 10 bit stream, below are the time domain modulations using both the half-sine pulse and SRRC pulse:

![](./imgs/Q2/Q2_mod.jpg)



AI Produced COmmentary Guide

  >    Half-Sine Modulation Observation:* In the top plot, the half-sine modulated signal appears as distinct, non-overlapping half-periods of a sine wave. Because the
  half-sine pulse is strictly defined to exist only between $0 \le t \le 1$ bit duration, each pulse begins exactly where the previous one ends. This time-limited
  nature ensures that, at the transmitter, there is zero overlap between adjacent symbols.
  >
  >    SRRC Modulation Observation:* In the bottom plot, the SRRC modulated signal looks entirely different. It does not look like distinct pulses; rather, it appears
  as a continuous, fluctuating waveform that resembles a smoothly varying analog signal. Because a single SRRC pulse spans 12 bit durations ($2K$), the pulses for the
  10 consecutive bits heavily overlap and interfere with each other. The amplitude at any given moment is the sum of the main lobe of the current bit and the decaying
  sidelobes (ripples) of several surrounding bits.

#### Q3: 

Below are the spectra of both the modulated signals:


Comments on the difference between the modulated signal spectrum and the pulse spectrum for both half sine and srrc:




Explain reasons for those differences.

AI commentary: 

We plotted the frequency spectrum of the 10-bit modulated signals (at the output of the pulse shaping filter) to compare them with the frequency spectrum of the
  single, isolated pulses from Question 1.
  >
  >    Overall Shape Similarity:* Yes, the modulated signal spectra have extremely similar overall "envelope" shapes compared to the single pulse spectra from Q1.
  >     *   The modulated half-sine signal still exhibits the characteristic wide main lobe and slowly decaying, high-frequency sidebands.
  >     *   The modulated SRRC signal still exhibits a flat passband near 0 Hz and a very sharp, steep roll-off defined by $\alpha = 0.5$, completely cutting off around
  0.75 Hz.
  >
  >    The Reason for Differences (The "Noise"):* While the overarching envelope shape is the same, the modulated spectra look much more jagged, "noisy," or erratic
  inside that envelope compared to the perfectly smooth curves of the single pulses in Q1.
  >
  >     This difference is entirely expected and is explained by the properties of the Fourier Transform.
  >
  >     The modulated signal in the time domain is essentially a convolution of the single pulse shape with a random sequence of impulse functions (our 10 random bits
  mapping to $+1$ or $-1$). In the frequency domain, convolution becomes multiplication. Therefore, the spectrum we see is the smooth frequency response of the single
  pulse filter multiplied by the random, erratic frequency spectrum of our 10-bit data sequence. The underlying pulse shape dictates the maximum possible bandwidth and
  the "ceiling" (envelope) of the energy, while the specific, random data sequence dictates the rapid fluctuations within that envelope.

#### Q4: 

Below are the eye diagrams for both pulses. 

Here is the half-sine eye diagram:

And here is the SRRC eye diagram:


Comments on these diagrams:


