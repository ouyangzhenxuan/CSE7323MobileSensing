# Lab2: Audio

### Module A
Create an iOS application using the example template that:

* Reads from the microphone
* Takes an FFT of the incoming audio stream
* Displays the frequency of the two loudest tones within (+-3Hz) accuracy 
  * Have a way to "lock in" the last frequencies detected on the display
* Is able to distinguish tones at least 50Hz apart, lasting for 200ms or more
* An idea for Exceptional Credit: recognize two tones played on a piano (down to one half step apart) and report them by letter (i.e., A4, A#4). Must work at note A2 and above. Note: this is harder than just identifying two perfect sine waves!!
* Exceptional Credit Idea (required for 7000 level students): make the FFT analysis follow the model-view-controller framework more closely. That is, make the model an analyzer that is not implemented in the View Controller (i.e., an "analyzer model"). All audio saving and analysis should happen in the model only, not the view controller. The audio analysis should be performed using blocks on a serial queue. Once analysis is complete, a view controller can ask the model for FFT frames, and the view controller can display those frames however it wants. You should design functions for accessing the result of the analyzer such that memory and computation time are reasonable. 
* Verify the functionality of the application to the instructor during lab time or office hours (or scheduled via email). The sound source must be external to the phone (i.e., laptop, instrument, another phone, etc.).

### Module B
Create an iOS application using the example template that:

* Reads from the microphone
* Plays a settable (via a slider or setter control) inaudible tone to the speakers (15-20kHz)
* Displays the magnitude of the FFT of the microphone data in decibels
* Is able to distinguish when the user is {not gesturing, gestures toward, or gesturing away} from the microphone using Doppler shifts in the frequency
