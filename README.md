# Create a virtual Drum Machine in a web page

```
# Roland TR-808

The Beastie Boys frequently used the Roland TR-808 drum machine in their music. This analog drum machine is known for its distinctive sounds, including a bassy kick, snappy snare, and a unique "cowbell" sound. The TR-808 was a significant influence on early hip-hop, techno, and dance music. The Beastie Boys even made direct references to the 808 in some of their songs, according to a Vintage Synth Explorer forum. 

The Roland TR-808 Rhythm Composer, commonly known as the 808, is a drum machine manufactured by Roland Corporation between 1980 and 1983. It was one of the first drum machines to allow users to program rhythms instead of using preset patterns. Unlike its nearest competitor at the time, the more expensive Linn LM-1, the 808 generates sounds using analog synthesis rather than by playing samples.

The 808 was a commercial failure, as electronic music had yet to become mainstream and many producers wanted more realistic drum sounds. After building approximately 12,000 units, Roland discontinued the 808 after its semiconductors became impossible to restock. It was succeeded by the TR-909 in 1983.

Over the course of the 1980s, the 808 attracted a cult following among underground musicians for its affordability on the used market, ease of use and idiosyncratic sounds, particularly its deep, booming bass drum. It became a cornerstone of the emerging electronic, dance and hip-hop genres, popularized by early hits such as "Planet Rock" by Afrika Bambaataa and the Soulsonic Force and "Sexual Healing" by Marvin Gaye.

The 808 was eventually used on more hit records than any other drum machine. Its popularity in hip-hop has made it one of the most influential inventions in popular music, comparable to the Fender Stratocaster's impact on rock. Its sounds are included with music software and modern drum machines and it has inspired unlicensed recreations. 

# Sounds and features
The 808 imitates acoustic percussion: the bass drum, snare, toms, conga, rimshot, claves, handclap, maraca, cowbell, cymbal and hi-hat (open and closed).[11] Rather than playing samples, it generates sounds using analog synthesis; the TR in TR-808 stands for "transistor rhythm".[12] The sounds do not resemble real percussion,[2][7] and have been described as "clicky",[7] "robotic",[10] "spacey",[3] "toy-like" and "futuristic".[2] Fact described them as a combination of synthesizer tones and white noise that resemble "bursts coming from the BBC Radiophonic Workshop" more than a real drum kit.[11] In Music Technology, Tim Goodyer described the cowbell as "clumsy, clonky and hopelessly underpitched".[13]

The 808 is noted for its powerful bass drum sound, built from a sine oscillator, low-pass filter and voltage-controlled amplifier.[14] The bass drum decay control allows users to lengthen the sound, creating uniquely low frequencies that flatten slightly over time, possibly not by design.[14] The New Yorker described the bass drum as the 808's defining feature.[10]

The 808 was the first drum machine with which users could program a percussion track from beginning to end, complete with breaks and rolls.[15] Users can program up to 32 patterns using the step sequencer,[5] chain up to 768 measures[16] and place accents on individual beats.[5] Users can also set the tempo[5] and time signature, including unusual signatures such as 5
4 and 7
8.[17] The 808 includes volume knobs for each voice, numerous audio outputs and a DIN sync port (a precursor to MIDI) to synchronize with other devices.[5] Its three trigger outputs can synchronize with synthesizers and other equipment.[18] 
```

The goal of this application is to recreate this Roland TR-808 in a web page.

The application is made in HTML, CSS, Javascript, Canvas, or any necessary client side technologies as necessary.
The application is served by a NodeJS server running locally.

```
 TR-808: Technical Specifications

    2 years ago Updated 

TR-808 RHYTHM COMPOSER

MEMORIZED RHYTHM NUMBER
BASIC RHYTHM A / AB / B 12 INTRO / FILL IN A / B 4

Step Number 1 Measure 1-32 steps

RHYTHM TRACK
64 Measures 12 Tracks (768 Measures)

THE INSTRUMENTS AND CONTROLS
BASS DRUM (BD) : LEVEL, TONE, DECAY
SNARE DRUM (SD) : LEVEL, TONE, SNAPPY
LOW CONGA (LC) :
LOW TOM TOM (LT) : LEVEL, TUNING
MID CONGA (MC) :
MID TOM TOM (MT) : LEVEL, TUNING
HI CONGA (HC) :
HI TOM TOM (HT) : LEVEL, TUNING
CLAVES (CL) :
RIM SHOT (RS) : LEVEL
MARACAS (MA) :
HAND CLAP (CP) : LEVEL
COW BELL (CB) : LEVEL
CYMBAL (CY) : LEVEL, TONE, DECAY
OPEN HI HAT (OH) : LEVEL, DECAY
CLOSED HI HAT (CH) : LEVEL
ACCENT (ac) : LEVEL

CONTROL SWITCHES, KEYS, KNOBS AND BUTTONS
MODE Selector (PATTERN WRITE - 1st PART, 2nd PART, MANUAL
PLAY, RHYTHM TRACK - PLAY, COMPOSE, PATTERN CLEAR)
INSTRUMENT / TRACK Selector (INSTRUMENT - SELECT, RHYTHM TRACK 1 - 12)
TEMPO Control (4M = 40 - 300)
FINE Control
AUTO FILL IN Selector (MANUAL, 16, 12, 8, 4, 2)
BASIC RHYTHM Button (1 - 12)
INTRO / FILL IN Button (1 - 4)
START / STOP Button
TAP Button (TAP, INTRO SET, FILL IN TRIGGER)
PRE - SCALE Selector (1, 2, 3, 4)
LEVEL Control (11 : ALL RHYTHMS)
ACCENT LEVEL
TONE Control (3 : BD, SD, CY)
MASTER VOLUME
Power On / Off Switch
CLEAR Button (PATTERN CLEAR, TRACK CLEAR, PRE - SCALE SET, STEP
NUMBER SET)
STEP Button (1 - 16)
BASIC VARIATION Switch (A, AB, B, Indicator A, B)
I / F VARIATION Switch (A, B)
TUNING Control (3 : LC = LT, MC = MT, HC = HT)
DECAY Control (3 : BD, CY, OH)
SNAPPY Control (1 : SD)
VOICE Selector (5 : LC - LT, MC - MT, HC - HT, CL - RS, MA - CP)

CONNECTION JACKS
MASTER OUT
HI : 6V P - / k ohms
LO :0.6 V P - P / 3 k ohms
(LEVEL : Standard - Red Mark, AC LEVEL : Max)
MULTI OUT: BD, SD, LC (LT), MC (MT), HC (HT), CL (RS), MA (CP),
CB, CY, OH, CH
TRIGGER OUT
CB, CP (MA), AC, ( + 15V, 20 ms pulse)
PEDAL SW
START / STOP (DP - 2)
INTRO / FILL N (DP - 2)
SYNC In / Out
DIN Connector (for CSQ - 600) (1 : START / STOP, 2 : GND, 3 : CLOCK)
INPUT OUTPUT Selector

POWER CONSUMPTION:
8 W

DIMENSIONS:
508 (W) x 305 (D) x 105 (H) mm

NET WEIGHT:
5 kg
```

# Usage

1. install libraries
2. start the server