(niet schrikken dit is niet alles, de rest staat ergens anders)

# BCI report

Matthijs Biondina<br>
Ward Theunisse<br>
Bob de Ruiter

__Summary__

We set out to build a BCI employing Bayesian prediction and classification of sensory anticipation. In addition, we discovered a Cybathlon BCI Race strategy that does not rely on any input, brain signals or otherwise, that consistently outperforms the world's best BCI racers.

## Introduction

The Cybathlon BCI Race is a novel game competition where contestants control a virtual avatar that has to cross a two-dimensional race track as quick as possible. It differs from a traditional game in that choosing the correct action for your avatar at any given moment is trivial, but informing the game of the action you intend your avatar to perform is not, as players are only allowed to communicate through a brain-computer interface.

https://www.extremetech.com/wp-content/uploads/2016/09/cybathlon-bci-race-screencap-640x424.png

Fig 1. The BCI race

The four box types shown in the screenshot above directly correspond to the four available actions: *slide*, *jump*, *speed*, and *rest*. If an avatar (continuously) performs the action that matches the box, it traverses the box in roughly ??? seconds. If it (continuously) performs any other action, it instead traverses the box in ??? seconds. The exception is the grey box, for which the speed bonus for selecting the correct action *rest* is significantly lower.

Within the constraints set by BCI, contestants are free to use any input modality of their choosing. As straightforward approaches like internal speech typically do not yield great results, most contestants instead opt for a proxy.

[training screenshot]
Fig 2. Buffer BCI**, the framework we based our implementation on, defaults to labels for imagined movement

## Ideas

__Tactile Anticipation__

We first investigated the possibility of improving the Buffer BCI by changing the task from imagined movement, which produces mu/beta ERDs (Beisteiner), to a task that alters the power of the alpha band, since alpha waves are the easiest to pick up using EEG [cit???].

Of everything we came across that could affect the alpha band, anticipation of tactile stimuli seemed most promising. Spatial orientation produces a suppression of contralateral sensorimotor alpha and beta band oscillations, so anticipation of a tactile event on the left hand can clearly be distinguished from anticipation of an event on the right (van der Ede). We hypothesized that once a person had been conditioned to expect a spatially specific stimulus depending on the type of box their avatar is on, they would automatically produce the correct brain signals, and we wouldn't have the risk of our brain racer messing up the commands. We also suspected that conditioning people into expecting certain tactile events on certain boxes is quicker and requires less of their effort than internalizing a mapping such as the one in figure 2.

Since the Cybathlon rules prohibit real tactile stimuli during the race, our racer might only anticipate stimulation during training, when it might actually occur, and not when it really matters. To counter this, we planned to train using multiple real BCI races as shown in figure 1 instead of the schematic representation shown in figure 2. The racer would be stimulated at random intervals on the left hand, right hand, or both, depending on the type of box they were on, or not at all, if they were on a grey box. At the start of the training, stimulation would be very frequent, but as it progressed, the rate would dwindle down to one or two tactile stimuli per race. Then, without notifying the racer, we would request a time registration and turn off the stimulators. At this point, the racer would still anticipate a stimulus throughout the official race even though they cannot receive one.

Initially, we considered the use of painful electrical stimuli to elicit a strong anticipatory response in the theta band (Larbig), but this was shot down due to practical concerns. The prospect of pain might cause such a heavy response that one cannot localize it. Also, even though the racer is in no danger of getting shocked during the official race, they might still accidentally violate the no-movement rule by contracting their muscles in anticipation to the stimulus. We also considered ticklish stimuli since anticipation to tickling gives a strong response that is very similar to the response to actual tickling (Carlsen), but we could not find any evidence of this response having increased lateralization.

In the end, we opted for vibration as it could easily be produced remotely using Servo motors.

__Bayesian Prediction__

Another idea 

## Methods



## Planning
