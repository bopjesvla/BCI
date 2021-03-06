ik in Word:

- Citaties
- Plaatjes plakken

# BCI report

Matthijs Biondina<br>
Ward Theunisse<br>
Bob de Ruiter

__Summary__

We set out to build a BCI employing Bayesian prediction and classification of sensory anticipation. In addition, we discovered a Cybathlon BCI Race strategy that does not rely on any input, brain signals or otherwise, that may outperform the world's best BCI racers.

## Introduction

The Cybathlon BCI Race is a novel game competition where contestants control a virtual avatar that has to cross a two-dimensional race track as quick as possible. It differs from a traditional game in that choosing the correct action for your avatar at any given moment is trivial, but informing the game of the action you intend your avatar to perform is not, as players are only allowed to communicate through a brain-computer interface.

https://www.extremetech.com/wp-content/uploads/2016/09/cybathlon-bci-race-screencap-640x424.png

Fig 1. The BCI race

The box types shown in the screenshot above directly correspond to the four available actions: *slide*, *jump*, *speed*, and *rest*. If an avatar continuously performs the action that matches the box, it traverses the box in roughly 2 seconds, except on the grey box, which a resting avatar traverses in 5 seconds. If it continuously performs *rest* on any other box, the avatar traverses the box in 11 seconds. If it performs any other action, it instead traverses the box in 18 seconds.

Within the constraints set by BCI, contestants are free to use any input modality of their choosing. As straightforward approaches like internal speech typically do not yield great results, most contestants instead opt for a proxy.

[training screenshot]
Fig 2. Buffer BCI**, the framework we based our implementation on, defaults to labels for imagined movement

While in the official championship contestants only got one official time registration, we had multiple chances, of which the last one counted. Although this change in rules promotes inconsistent BCIs with wildly fluctuating times, as teams can simply stop when they hit a high, we set out to build consistently high-performing BCI.

## Ideas

__Tactile Anticipation__

We first investigated the possibility of improving the Buffer BCI by changing the task from imagined movement, which produces mu/beta ERDs (Beisteiner), to a task that alters the power of the alpha band, since alpha waves are the easiest to pick up using EEG [cit???].

Of everything we came across that could affect the alpha band, anticipation of tactile stimuli seemed most promising. Spatial orientation produces a suppression of contralateral sensorimotor alpha and beta band oscillations, so anticipation of a tactile event on the left hand can clearly be distinguished from anticipation of an event on the right (van der Ede). We hypothesized that once a person had been conditioned to expect a spatially specific stimulus depending on the type of box their avatar is on, they would automatically produce the correct brain signals, and we wouldn't risk our brain racer messing up the commands. We also suspected that conditioning people into expecting certain tactile events on certain boxes is quicker and requires less of their effort than internalizing a mapping such as the one in figure 2.

Since the Cybathlon rules prohibit real tactile stimuli during the race, we worried our racer might only anticipate stimulation during training, when it actually occurs, and not during the official race, when the racer knows they won't be stimulated. To counter this, we trained using multiple real BCI races as shown in figure 1 as opposed to a schematic representation shown in figure 2. This way, feedback is implicit in the task, because the user observes whether the avatar speeds up or slows down. Stimulation would occur at random frequency, on the left hand, right hand, or both, depending on the color of the box they were on, or not at all, if they were on a grey box. At the start of the training (taking place over multiple race sessions), stimulation would be frequent, but as the training progressed, the rate would dwindle down to one or two tactile stimuli per race. Then, without notifying the racer, we would request a time registration and turn off the biofeedback device. If everything went right, the racer would still anticipate a stimulus throughout the official race even though they could not receive one. The student-assistants agreed to cooperate on this.

Training using the BCI race has the additional benefit that the neurofeedback takes the same form during training as during the official race, namely avatar speed. This means that the training would not only condition the racer to generate certain anticipatory brain signals in response to certain situations, but it also teaches the racer to change their brain signals whenever their avatar moves slowly, for example by increasing their attention to where they expect the stimulus.

Initially, we considered the use of painful stimuli to elicit a strong anticipatory response in the theta band (Larbig), but this was shot down due to ethical and safety concerns. Additionally, the prospect of pain might cause such a heavy response that one cannot localize it. Also, even though the racer is in no danger of getting hurt during the official race, they might accidentally violate the no-movement rule in anticipation to the stimulus. We also considered ticklish stimuli. Anticipation to tickling gives a strong response that is very similar to the response to actual tickling (Carlsen), but we could not find any evidence of this response being lateralized.

In the end, we opted for vibration as it is purely tactile, like the Braille cells van der Ede et al. used, and it could easily be generated by rotating motors.

__Bayesian Prediction__

We used Bayesian Probability logic to determine the probability for each command that that command was the task intended by the participant, based on the classifier results over a small period of time (3 seconds) and the accuracy of each class in the classifier. Given the probabilities of these commands and the speeds they result in when they are correct or incorrect, we can calculate the expected speed of the avatar for each command and send the one with the highest expected speed to the game.

For example, say that over a period of 3 seconds the classifier returns the predictions *speed*, *jump*, *speed*. If the specificity of the *speed* command is high and the specificity for the *jump* command is low, the expected speed of the avatar when sending *speed* to the game will probably be highest, therefore the agent sends *speed* to the game. On the other hand if the specificity for the *speed* command is low and the specificity for the *jump* command is high, the amount of uncertainty about the intended command will probably be too high and the expected speed for *rest* will be highest. Therefore the agent would not send a command to the game.

A full pen-and-paper formalization of our prediction strategy can be found in Appendix A.

__Zero Input Strategy__

While working on the Bayesian prediction, we realized that by cycling through the *slide*, *jump*, and *speed* commands every 6 seconds (2 seconds per command), the avatar could traverse every colored box between 2 and 6 seconds, at the cost of traversing grey boxes in 18 seconds. Assuming one in four boxes are grey and the race track consists of 14 boxes, the avatar takes 126 seconds to cross the finish line on average, which matches the top Cybathlon 2016 time.

## Implementation

__Tactile Anticipation__

To train the classifier using the BCI race, we had to know the current box type, which matches the current classification category, at any given point in time. Unfortunately, the BCI race does not expose any API, so we were forced to extract color data from the screen to determine the rail car type. Luckily, the camera angle can be locked to your player so we wrote a Python script to extract data from the Cybathlon window at the coordinate that always pointed to the front side of the box directly below the avatar. Because the lighting in the game was not one even colour on the entirity of a rail car, the class was selected that was closest to the found colour.

This Python script also communicated with the sensors, in order to create a tactile sensation for a certain class with a given chance. Furthermore, in order to train the classifier this script also communicated with the FieldTripBuffer in the same way that the provided abstract BCI trainer did, so the data could be used.

Vibration was generated using servos controlled by an Arduino, kindly supplied by the New Devices Lab in Mercator 1. The Arduino program listened on serial port for the action to perform (the Python script decides if given a rail car class an actual vibration has to be generated, the Arduino just functions as an interface between the script and the servos) and periodically quickly rotated the motor strapped to the left, right, or both hands based on the latest signal.

We are confident we got all of this working based on test data, but our time record was not set using the tactile anticipation method. This is because we were, at the time, more concerned with setting a base line time to work on, since time was running out. The implementation lives on github in the master branch of bopjesvla/BCI.

__Bayesian Prediction & Zero Input Strategy__

Both Bayesian prediction and the zero input strategy were fully implemented in Matlab, by altering the prediction strategy in `imEpochFeedbackCybathalon.m`.

We also implemented a semi-random strategy, which classified between only two categories, rest and cycling. When the rest category was detected, the agent sent no command to the game, when the cycling category was detected, the agent cycled through the three commands with 2 second intervals. In our final time registration, the racer performed imagined movement on the entire left side of their body for rest, and imagined movement on the entire right side of their body for cycling. Buffer BCI enforced a minimum of three categories because of a bug we were unable to resolve, so we used two identical categories for the right side of the body.

## Experiment

We compared the performance of our three strategies to two baseline conditions: the default imagined movement strategy and the performance of the population of Cybathlon 2016 BCI Race finalists. The latter was mainly included to see if our random strategy performed better on average than the finalists.

For the Bayesian and default strategies, we trained the classifier using the default Buffer BCI training. For the semi-random strategy, we altered the categories as described above.

After each training, we recorded the times of four sequential unofficial races per strategy, in addition to one registered time per strategy. Every strategy was tested in a different session as we implemented two of them in the last few sessions, but they were all performed by the same racer.

The random strategy was tested five times without any input.

## Results

<small>in seconds, official times in ***bold italic***</small>

__Recorded Baseline Times__

Classifier performance: unknown

162.24
210.56
183.92
193.47
187.51

__Recorded Bayesian Times__

Classifier performance: 33% over four categories

196.38
140.66
105.63
145.98
***133.98***

__Recorded Random Times__

126.27
140.32
100.23
118.14
121.06

__Recorded Semi-Random Times__

Classifier performance: 34% over three categories

125.09
149.26
102.32
116.55
***118.11***

__Cybathlon 2016 BCI Race Finals__ (times taken from the video at http://blog.gtec.at/brain-tweakers-won-bci-race-2016/)

125.23
156.33
161.15
170 (friendly estimate)

[ANOVA]

HSD[.05]=41.78; HSD[.01]=52.47
IM vs Bayesian   P<.05
IM vs Random   P<.01
IM vs Semi-Rnd   P<.01
IM vs Prof   nonsignificant
Bayesian vs Random   nonsignificant
Bayesian vs Semi-Rnd   nonsignificant
Bayesian vs Prof   nonsignificant
Random vs Semi-Rnd   nonsignificant
Random vs Prof   nonsignificant
Semi-Rnd vs Prof   nonsignificant

## Conclusions

We found a significant difference in performance between the five categories. In particular, we found that all of our strategies performed significantly better than the default Buffer BCI strategy. Although we failed to record the classifier performance during the imagined movement test, we are quite sure it was higher than the classifier performance in the Bayesian test. It was definitely higher than the classifier performance in the semi-random test, which is effectively random with a strong bias for cycling.

We did not find a significant difference in performance between the random strategy and the official Cybathlon times, but this may be due to the small sample sizes. In any case, it seems unlikely that the official Cybathlon racers perform better than the cycling strategy. The average cycling performance lies two standard deviations ahead of the average finalist.

This means that as it stands, the BCI Race does not meet the goal stated on the Cybathlon website, "testing the reliability and precision of BCI technology".

## Planning



## Literature

## Appendix A

Picture of Matthijs' formalization, note the tp/fp mistake
