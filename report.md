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

The four box types shown in the screenshot above directly correspond to the four available actions: *slide*, *jump*, *speed*, and *rest*. If an avatar (continuously) performs the action that matches the box, it traverses the box in roughly ??? seconds. If it (continuously) performs any other action, it instead traverses the box in ??? seconds. The exception is the grey box, for which the speed bonus for selecting the correct action *rest* is significantly lower.

Within the constraints set by BCI, contestants are free to use any input modality of their choosing. As straightforward approaches like internal speech typically do not yield great results, most contestants instead opt for a proxy. Buffer BCI**, the framework we based our implementation on, defaults to labels for imagined movement:

[training screenshot]

## Ideas

We first investigated the possibility of improving the Buffer BCI by changing the task from imagined movement, which produces mu/beta ERDs [cit], to a task that alters the power of the alpha band, since alpha waves are the easiest to pick up using EEG [cit???].

Anticipation of tactile events grabbed our attention because it causes both motor cortex somatosoric cortex [cit], contrast IM, to our knowledge no BCI using this

Pain, prospect strong reaction, distortions homunculus, ethics, anticipation to vibration easier

## Methods

## Planning
