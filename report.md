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

The three colored box types shown in the screenshot above directly correspond to three of the four available actions: *slide*, *jump*, and *speed*. If an avatar continuously performs the action that matches the box, it traverses the box in roughly ??? seconds. If it continuously performs any other action, it instead traverses the box in ??? seconds. The exception is the *rest* action, which always causes the avatar to traverse a box in ??? seconds. Resting is optimal on the grey box, since no other action is available there.

Within the constraints set by BCI, contestants are free to use any input modality of their choosing. As straightforward approaches like internal speech typically do not yield great results, most contestants instead opt for a proxy.

[training screenshot]
Fig 2. Buffer BCI**, the framework we based our implementation on, defaults to labels for imagined movement

While in the official championship contestants only got one official time registration, we had multiple chances, of which the last one counted. Although this change in rules promotes inconsistent BCIs with wildly fluctuating times, as teams can simply stop when they hit a high, we set out to build consistently high-performing BCI.

## Ideas

__Tactile Anticipation__

We first investigated the possibility of improving the Buffer BCI by changing the task from imagined movement, which produces mu/beta ERDs (Beisteiner), to a task that alters the power of the alpha band, since alpha waves are the easiest to pick up using EEG [cit???].

Of everything we came across that could affect the alpha band, anticipation of tactile stimuli seemed most promising. Spatial orientation produces a suppression of contralateral sensorimotor alpha and beta band oscillations, so anticipation of a tactile event on the left hand can clearly be distinguished from anticipation of an event on the right (van der Ede). We hypothesized that once a person had been conditioned to expect a spatially specific stimulus depending on the type of box their avatar is on, they would automatically produce the correct brain signals, and we wouldn't risk our brain racer messing up the commands. We also suspected that conditioning people into expecting certain tactile events on certain boxes is quicker and requires less of their effort than internalizing a mapping such as the one in figure 2.

Since the Cybathlon rules prohibit real tactile stimuli during the race, we worried our racer might only anticipate stimulation during training, when it actually occurs, and not during the official race, when the racer knows they won't be stimulated. To counter this, we planned to train using multiple real BCI races as shown in figure 1 instead of a schematic representation shown in figure 2. Stimulation would occur at random intervals on the left hand, right hand, or both, depending on the color of the box they were on, or not at all, if they were on a grey box. At the start of the training, stimulation would be frequent, but as the training progressed, the rate would dwindle down to one or two tactile stimuli per race. Then, without notifying the racer, we would request a time registration and turn off the stimulators. If everything went right, the racer would still anticipate a stimulus throughout the official race even though they could not receive one. The student-assistants agreed to cooperate on this.

Training using the BCI race has the additional benefit that the neurofeedback takes the same form during training as during the official race, namely avatar speed. This means that the training would not only condition the racer to generate certain anticipatory brain signals in response to certain situations, but it also teaches the racer to change their brain signals whenever their avatar moves slowly, for example by increasing their attention to where they expect the stimulus.

Initially, we considered the use of painful stimuli to elicit a strong anticipatory response in the theta band (Larbig), but this was shot down due to practical concerns. The prospect of pain might cause such a heavy response that one cannot localize it. Also, even though the racer is in no danger of getting hurt during the official race, they might accidentally violate the no-movement rule in anticipation to the stimulus. We also considered ticklish stimuli. Anticipation to tickling gives a strong response that is very similar to the response to actual tickling (Carlsen), but we could not find any evidence of this response being lateralized.

In the end, we opted for vibration as it is purely tactile, like the Braille cells van der Ede et al. used, and it could easily be generated by rotating motors.

__Bayesian Prediction__

The optimal action is not necessarily the action the classifier thinks is most likely the intended action. For example, given the classifiers entries X and Y, according to Bayes' theorem (Olshausen), [simple two-class example using real traversal times???]

A full pen-and-paper formalization can be found in Appendix A.

__Zero Input Strategy__

While working on the Bayesian prediction, we realized that by cycling through the *slide*, *jump*, and *speed* commands every ??? seconds, the avatar could traverse every colored box between ??? and ??? seconds, at the cost of traversing grey boxes in ??? seconds. Assuming one in four boxes are grey and the race track consists of 14 boxes, the avatar takes ??? seconds to cross the finish line on average, well below the official Cybathlon 2016 times.

## Implementation

To train the classifier using the BCI race, we had to know the current box type, which matches the current classification category, at any given point in time. Unfortunately, the BCI race does not expose any API, so we were forced to extract color data from the game to determine the box type. Luckily, the camera angle is constant when only one person plays the game, so we used Python to extract data from the Cybathlon window at the coordinate that always pointed to the front side of the box below the avatar.

During training, we also wanted to 

## Results

## Planning
