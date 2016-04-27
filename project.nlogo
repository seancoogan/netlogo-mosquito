breed [ females female ]              ;; Female mosquito breed of turtles
breed [ males male ]                  ;; Male mosquito breed of turtles
breed [ deployments deployment ]      ;; GMO mosquito release sites breed of turtles

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Female variables ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

females-own [   
  compatibility                       ;; Random number that must match for mosquitoes to mate (integer)
  life-time                           ;; Remaining life in number of ticks (integer)
  pregnant?                           ;; Boolean flag to track if female is pregnant (boolean)
  preg-count                          ;; Counter to track number of pregnancies (integer)
  target                              ;; Patch where female will lay eggs (patch)
  rest-count                          ;; Counter for length of time between pregnancies (integer)
]

;;;;;;;;;;;;;;;;;;;;;;
;;; Male variables ;;;
;;;;;;;;;;;;;;;;;;;;;;

males-own [ 
  compatibility                       ;; Random number that must match for mosquitoes to mate (integer)
  life-time                           ;; Remaining life in number of ticks (integer)
  gmo?                                ;; Boolean flag to track if mosquito is GMO (boolean)
]

;;;;;;;;;;;;;;;;;;;;;;;
;;; Patch variables ;;;
;;;;;;;;;;;;;;;;;;;;;;;

patches-own [ 
  water?                              ;; Flag to track if patch represents water (boolean)
  wild-eggs                           ;; Counter for number of wild eggs on a patch (integer)
  gmo-eggs                            ;; Counter for number of GMO eggs on a patch (integer)
]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; Global variables ;;;
;;;;;;;;;;;;;;;;;;;;;;;;

globals [
  total-wild-eggs                     ;; Counter for wild eggs laid (integer)
  total-gmo-eggs                      ;; Counter for GMO eggs laid (integer)
]

;;;;;;;;;;;;;
;;; Setup ;;;
;;;;;;;;;;;;;

to setup                              ;; Observer procedure
  clear-all                           ;; Initialize environment by clearing all agents   
  reset-ticks                         ;; Reset tick count to 0
  set total-wild-eggs 0               ;; Initialize global total wild eggs counter to 0
  set total-gmo-eggs 0                ;; Initialize global total GMO eggs counter to 0
  
  set-default-shapes                  ;; Apply default shapes to turtle breeds
  setup-patches                       ;; Setup initial patches 
  setup-deployments                   ;; Setup initial GMO release locations 
end

to set-default-shapes                 ;; Turtle procedure
  ;; Define shapes to represent each turtle breed
  set-default-shape females "butterfly"  
  set-default-shape males "butterfly"
  set-default-shape deployments "box"
end

to setup-patches                      ;; Patch procedure
  ;; Initialize all patches
  ask patches [
    set water? false                  ;; Not water
    set wild-eggs 0                   ;; Patch has 0 wild eggs
    set gmo-eggs 0                    ;; Patch has 0 GMO eggs
  ]
  setup-water                         ;; Call sub procedure 
end

to setup-water                        ;; Patch procedure
  ;; Create three water sources
  ask patches [
    ;; setup water source one on the right
    if (distancexy (0.6 * max-pxcor) 0) < 2
    [ setup-water-patch ]
    ;; setup water source two on the lower-left
    if (distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 2
    [ setup-water-patch ]
    ;; setup water source three on the upper-left
    if (distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 2
    [ setup-water-patch ]
  ]
end

to setup-water-patch                  ;; Patch procedure
  ;; Initialize water patches
  set water? true                     ;; Is water
  set wild-eggs random 50             ;; Each water patch starts with 0-49 wild eggs
  set pcolor cyan                     ;; Color water patches light blue
  ;; Update global total wild egg counter
  set total-wild-eggs total-wild-eggs + wild-eggs
end

to setup-deployments                  ;; Patch procedure
  ;; Create one deployment location on n-number of random patches, 
  ;; where n is initial-release-locations set from interface
  ask n-of initial-release-locations patches [  ;; create a deployment turtle on random patches
    sprout-deployments 1 [  
      set color red                   ;; Color deployments red
      set size 2                      ;; Lager size, easier to see
    ]
  ] 
end

;;;;;;;;;;
;;; Go ;;;
;;;;;;;;;;  

to go                                 ;; Observer procedure, forever button
  if (total-wild-eggs = 0 and total-gmo-eggs = 0 and count females = 0 and count males = 0) [
    stop                              ;; Stop simulation when there are no more mosquitoes and eggs
  ]
  
  gmo-release-location                ;; Monitor for deployment location movements 
  hatch-eggs                          ;; Hatch eggs, 1 per patch (where applicable)
  
  ask females [ 
    if not pregnant? [ find-mate ]    ;; Female mosquitoes look for a male mate
    if pregnant? [ find-water-to-lay-eggs ]  ;; When pregnant find water to lay eggs
    if not pregnant? [ mingle ]       ;; If not pregnant, continue looking for mate
    advance-life                      ;; Call sub procedure to keep track of life time remaining
  ]
  ask males [
    mingle                            ;; Call sub procedure to 
    advance-life                      ;; Call sub procedure to keep track of life time remaining
  ]
  
  tick                                ;; Advance ticks
end

to release-gmo                        ;; Observer procedure, Button 
  ;; This button triggered procedure creates n-number of GMO male mosquitoes at the patch where each deployment 
  ;; box is positioned, where n is the gmo-release-per-deployment set from slider in interface. This runs every 
  ;; the button is pressed
  ask deployments [
    ask patch-here [ 
      release-gmo-males gmo-release-per-deployment 
    ]
  ]
end

to release-gmo-males [ num ]          ;; Patch procedure
  ;; Create n-number of GMO male mosquitoes, where n is the parameter num
  sprout-males num [
    sprout-gmo-male                   ;; Call sub procedure to create a GMO male
  ]
end

to gmo-release-location               ;; Deployment breed turtle procedure
                                      ;; While Go procedure is running, this procedure 
                                      ;; monitors if user mouse drags a deployment turtle
  if mouse-down? [
    let candidate min-one-of deployments [distancexy mouse-xcor mouse-ycor]
    if [distancexy mouse-xcor mouse-ycor] of candidate < 1 [
      ;; The WATCH primitive puts a "halo" around the watched turtle.
      watch candidate
      while [mouse-down?] [
        ;; If we don't force the view to update, the user won't
        ;; be able to see the turtle moving around.
        display
        ;; The SUBJECT primitive reports the turtle being watched.
        ask subject [ setxy mouse-xcor mouse-ycor ]
      ]
      ;; Undoes the effects of WATCH.  Can be abbreviated RP.
      reset-perspective
    ]
  ]
end

to hatch-eggs                         ;; Patch procedure
  ;; This procedure hatches an egg on each water patch where an egg exists  
  ask patches with [ water? = true and (wild-eggs > 0 or gmo-eggs > 0) ] [
    ;; If both wild and GMO eggs exist, one is chose randomly 
    ifelse (wild-eggs > 0 and gmo-eggs > 0) [
      ifelse one-of [ true false ] [
        ;; hatch wild eggs
        hatch-wild-egg
      ]
      [
        ;; hatch gmo eggs
        hatch-gmo-egg
      ]
    ]
    [  
      ifelse wild-eggs > 0 [
        ;; Only wild eggs exist
        ;; hatch wild eggs 
        hatch-wild-egg
      ]
      [
        ;; Only gmo eggs exist
        ;; hatch gmo eggs 
        hatch-gmo-egg
      ]
    ]
  ]
end

to hatch-wild-egg                     ;; Patch procedure
  ;; This procedure creates a non GMO mosquito if a random number between 0 and 100
  ;; is less than or equal to the wild-survival-rate set on the interface slider   
  if random 101 <= wild-survival-rate [  
    ;; Randomly choose to create a wild male or wild female   
    ifelse one-of [ true false ] [
      sprout-females 1 [
        set color pink                ;; Color pink to indicate wild (non GMO), fertile female
        set compatibility random 10   ;; Random compatibility number between 0 and 9
        ;; Life span will be a random number between 3 and 10 and a random multiplier between 2 and 5
        ;; This represents the fact that female mosquitoes can live up to 5 times longer than males
        set life-time (3 + random 8) * (2 + random 4)   
        set pregnant? false           ;; Female specific variables, indicates non GMO
        ;; Female specific variables, counter for random maximum number of pregnancies in the 
        ;; females life time. Random number between 1 and 3
        set preg-count 1 + random 3    
      ]
    ]
    [ 
      sprout-males 1 [
        set color blue                ;; Color blue to indicate wild (non GMO) male
        set compatibility random 10   ;; Random compatibility number between 0 and 9
        set life-time 3 + random 8    ;; Life span will be a random number between 3 and 10
        set gmo? false                ;; Male specific variables, indicates non GMO
      ]
    ]
  ]
  set wild-eggs wild-eggs - 1         ;; Decrement wild egg counter for this patch
  set total-wild-eggs total-wild-eggs - 1  ;; Decrement global total wild egg counter
end

to hatch-gmo-egg                      ;; Patch procedure
  ;; This procedure creates an GMO mosquito if a random number between 0 and 100
  ;; is less than or equal to the gmo-survival-rate set on the interface slider       
  if random 101 <= gmo-survival-rate [
    ;; Since females produced from GMO eggs do not survive to adulthood, we only produce GMO males 
    sprout-males 1 [
      sprout-gmo-male
    ]
  ]
  set gmo-eggs gmo-eggs - 1           ;; Decrement GMO egg counter for this patch
  set total-gmo-eggs total-gmo-eggs - 1  ;; Decrement global total GMO egg counter
end

to sprout-gmo-male                    ;; Patch procedure
  set color red                       ;; Color red to indicate GMO male
  set compatibility random 10         ;; Random compatibility number between 0 and 9
  set life-time 3 + random 8          ;; Life span will be a random number between 3 and 10
  set gmo? true                       ;; Male specific variables, indicates GMO 
end

to find-mate                          ;; Female breed turtle procedure
  if color = pink and preg-count > 0 [   ;; Double check only fertile female
    ;; Randomly select a male with in a radius of 3 
    let mate min-one-of males in-radius 3 [distance myself]
    ;; Error handler against no male getting selected
    if mate != nobody [
      ;; Check compatibility matches 
      if [compatibility] of mate = [compatibility] of self [
        fertilize [gmo?] of mate      ;; Fertilize this female based passing GMO flag male mate
      ]
    ]
  ]
end

to fertilize [gmo-flag?]              ;; Female breed turtle procedure
  ;; This procedure fertilizes the female given the gmo? flag parameter
  set pregnant? true                  ;; Flag indicates this female is now pregnant
  set rest-count 5                    ;; Females must rest at least 5 ticks between pregnancies 
  set preg-count preg-count - 1       ;; Decrement pregnancy counter
  ifelse gmo-flag? [                  ;; If fertilized by a GMO male
    set color green                   ;; Color green to identify carrying GMO eggs
  ]
  [
    set color violet                  ;; Color violet to identify carrying wild eggs
  ]  
end

to find-water-to-lay-eggs             ;; Female breed turtle procedure
  if pregnant? [                      ;; Double check only pregnant female
    find-water                        ;; Look for water patch
    ;; Error handler against no patch getting selected
    ifelse target = nobody [
      ;; If no water patch is found, keep looking
      mingle
    ]
    [ 
      ifelse patch-here = target [
        ;; If current patch is the targeted water patch and rested long enough, lay eggs
        if rest-count <= 0 [
          lay-eggs
        ]
      ] 
      [ 
        ;; If current patch is not the targeted water patch, change heading to the target
        face target
        forward 1                     ;; Move forward 1 
      ] 
    ]
    set rest-count rest-count - 1     ;; Decrement rest counter
  ]
end

to find-water                         ;; Female breed turtle procedure
  ;; Look for water patches with in a 180 degree view, distance of 10, and colored cyan
  let targets (patches in-cone 10 180 ) with [pcolor = cyan] 
  ;; Choose the closest water patch and set the female member variable 
  set target min-one-of targets [ distance myself ] 
end

to lay-eggs                           ;; Female breed turtle procedure
  ;; This procedure lays random number of eggs (0 to 299), either wild (non GMO) or 
  ;; GMO depending on which type of male she mated 
  let new-eggs random 300
  if color = violet [                 ;; Lay wild eggs on current patch
    set wild-eggs wild-eggs + new-eggs
    set total-wild-eggs total-wild-eggs + new-eggs  ;; Update global total wild egg counter
  ]
  if color = green [                  ;; Lay GMO eggs on current patch
    set gmo-eggs gmo-eggs + new-eggs
    set total-gmo-eggs total-gmo-eggs + new-eggs  ;; Update global total GMO egg counter
  ]
  set pregnant? false                 ;; Reset pregnancy flag to false
  set color pink                      ;; Reset color to pink to indicate fertile
  set rest-count 0                    ;; Reset rest counter to 0
end

to mingle                             ;; Female and male breed turtle procedure
  right flutter-amount 45             ;; Turn right random amount
  left flutter-amount 45              ;; Turn left random amount
  forward 1                           ;; Move forward 1
end

to-report flutter-amount [limit]      ;; Female and male breed turtle procedure
  ;; This procedure takes a number as an input and returns a random value between
  ;; (+1 * input value) and (-1 * input value).
  ;; It is used to add a random flutter to the mosquito's movements
  report random-float (2 * limit) - limit
end

to advance-life                       ;; Female and male breed turtle procedure
  set life-time life-time - 1         ;; Decrement life counter
  if life-time < 0 [ die ]            ;; If life expired, turtle die
end
@#$#@#$#@
GRAPHICS-WINDOW
230
10
773
574
20
20
13.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
8
133
78
166
SETUP
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
87
133
150
166
GO
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
9
346
94
391
Wild Eggs
total-wild-eggs
17
1
11

MONITOR
102
401
187
446
GMO Infected
count males with [color = red] + count females with [color = green]
17
1
11

SLIDER
8
93
183
126
initial-release-locations
initial-release-locations
0
10
6
1
1
NIL
HORIZONTAL

TEXTBOX
10
10
228
84
First, set initial-deployment-locations (the number of GMO release sites). Then SETUP and GO. While running, \ndrag red boxes to move deployment locations.\n
12
0.0
1

SLIDER
9
260
187
293
wild-survival-rate
wild-survival-rate
0
100
20
1
1
%
HORIZONTAL

SLIDER
9
302
188
335
gmo-survival-rate
gmo-survival-rate
0
100
40
1
1
%
HORIZONTAL

MONITOR
102
346
186
391
GMO Eggs
total-gmo-eggs
17
1
11

MONITOR
9
400
94
445
Uninfected
count males with [color = blue]\n+ count females with [color = pink]\n+ count females with [color = violet]
17
1
11

PLOT
782
11
1172
288
Eggs
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Wild" 1.0 0 -13345367 true "" "plot total-wild-eggs"
"GMO" 1.0 0 -2674135 true "" "plot total-gmo-eggs"

PLOT
782
297
1173
573
Mosquitoes
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Wild" 1.0 0 -13345367 true "" "plot count males with [color = blue] + count females with [color = pink] + count females with [color = violet]"
"GMO" 1.0 0 -2674135 true "" "plot count males with [color = red] + count females with [color = green]"

SLIDER
9
178
218
211
gmo-release-per-deployment
gmo-release-per-deployment
10
100
50
10
1
NIL
HORIZONTAL

BUTTON
9
217
120
250
Release GMO
release-gmo
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@


## WHAT IS IT?

This model explores the eradication of Aedes aegypti mosquitoes through the use of genetically modified (GMO) male mosquitoes. The Aedes aegypti has turned to a significant public health threat. It is a vector of several for transmitting ZIKA and other tropical fevers. Conventional control methods have failed to control the population of mosquitoes so far. Novel genetics-based strategies offer a promising alternative or aid towards efficient control of this mosquito.

Current genetics-based strategies have two different methods, Bi-sex RIDL and fs-RIDL (female specific). Bi-sex RIDL will cause that both male and female offspring die before adulthood. This method requires continuous releases of the GMO mosquitoes to the wild. It could significantly reduce the population but hard to eradicate the mosquitoes. On the other hand fs-RIDL (female specific) targets on the female offspring ensuring they fail to survive until adulthood. Meanwhile, male offspring will grow up with the lethal gene and continue to mate with other wild female. In favorable circumstances, modified gene is spread automatically. 

This model focuses exclusively on the fs-RIDL method. The goal of this model is to help the user choose the ideal locations and quantity of GMO mosquitoes to release while providing the most effective results for the practice.

## HOW IT WORKS

Mosquitoes hatch from eggs in bodies of water represented by cyan colored patches. Once hatched, the adult mosquitoes attempt to mate with compatible mosquitoes of the opposite sex. Genetically modified (GMO) male mosquitoes are released by the user who controls release locations, quantities, and number of releases. The mosquito agents fly around in the open, unbound world, interacting with others, testing compatibility, and attempting to mate. 

Successful mating requires a non-pregnant, fertile female and a male with in a radius of 3 units of the female. There is a compatibility variable (0-9) that must match for the female and male to mate successfully. This represents the variable frequency used for mosquitoes to find a mate. Once a suitable mate is found, the fertilized female seeks out the nearest water patch within her field of view (180 degree, 10 distance). After waiting a rest period of 5 ticks, she lays 0 to 300 eggs. The eggs laid are of type wild (non-GMO) or GMO depending on the genetic make up of her male partner. Females can get pregnant a random number of times (1 - 3). After eggs have been laid, the female resumes seeking a mate. 

Male mosquitoes have a life span, randomly set, ranging from 3 to 10 ticks. The life span of females is also a random number between 3 and 10 but with a random multiplier between 2 and 5. This represents the fact that female mosquitoes can live up to 5 times longer than males.

On each tick each water patch, if applicable, hatches 1 egg. If both wild (non-GMO) and GMO eggs exist on said patch, one is chosen at random. A user controlled survival rate for both wild (non-GMO) and GMO determines the odds that the egg will successfully hatch. Since females produced from GMO eggs do not survive to adulthood, only GMO males are produced. The new generations of mosquitoes then proceed to seek mates, thus continuing the cycle.

## HOW TO USE IT

Prior to Setup, the initial release locations should be set using the initial-release-locations slider. This sets the number of GMO deployment locations ranging from 0 to 10. These deployment locations are represented by red boxes in the environment. 

Next simulation initialization is invoked using the SETUP button. This creates the aforementioned deployment locations as well as three bodies of water represented by cyan colored patches. With in these patches are an initial random (0-49) amount of wild (non-GMO) eggs. 

To start the simulation, the GO button is pressed. This button has the forever option selected to keep the simulation running continuously until subsequent pressing of the GO button. Once running, eggs will hatch producing adult mosquitoes. These mosquitoes will attempt to reproduce as detailed in the previous sections.

While the simulation is running the user can position the release locations for the genetically modified mosquitoes by dragging each red box using the mouse to place them anywhere in the environment.  

The number of GMO male mosquitoes to be released per location is set using the gmo-release-per-deployment slider, ranging from 0 to 100. Note, this is per location so multiply this number by the total number of locations to get the total number of GMO males that will be deployed each time the Release GMO button is pressed. 

Once release settings are configured, press the Release GMO button. This can be pressed any number of times. Each press will release the set number of GMO mosquitoes from the current locations. Locations and gmo-release-per-deployment can be changed through out the simulation run.

Survival rate of wild (non GMO) and GMO mosquitoes are controlled by the wild-survival-rate and gmo-survival-rate respectively. This is the success rate that a hatched egg will produce an adult mosquito. This represents the reality that not all eggs laid result in adult mosquitoes that are able to reproduce in their own rite.

On the bottom left side you will find several counters display the total tally of wild (non-GMO) egg, GMO eggs, uninfected adult mosquitoes, and adult mosquitoes that have been infected with the mutated gene.

On the right side there are two plots that historically track the eggs and mosquito populations. The plot titled Eggs plots wild (non-GMO) egg in blue and GMO eggs in red. The plot titled Mosquitoes plots wild (non-GMO) mosquitoes in blue and GMO mosquitoes in red.

## THINGS TO NOTICE

If the survival rate of GMO mosquitoes is higher than the survival rate of wild (non GMO) mosquitoes, the extinction will happen very fast. If GMO mosquitoes and wild (non GMO) mosquitoes have the same survival rate, with the same release number, it will take a much longer time to generate a complete eradication. In a wild environment, the survival rate of wild mosquitoes is about 20%.

Changing the position of deployment points, such as put them together, or put them far from each other, would not significantly affect the result. However, putting deployment points near the water could accelerate the eradication time, especially when the number of deployment points is low.


## THINGS TO TRY

Try different values for the INITIAL-RELEASE-LOCATIONS, GMO-REALEASE-PER-DEPLOYMENT, WILD-SURVIVAL-RATE, and GMO-SURVIVAL-RATE sliders. How do they affect the number of eggs and number of mosquitoes?

Try to drag the DEPLOYMENT POINT. Does it affect the eradication process?

Is there a significant change in results when pressing the Release GMO button multiple time to simulate multiple deployments?

## EXTENDING THE MODEL

There are a number of ways to alter the model, so it will make the model closer to reality. Some will require new elements to be coded in or existing behaviors to be changed. 

Add more user control of different species of mosquitoes. This somewhat implied by the compatibility variable but could be expanded upon.

Add hatch time to closer resemble the developmental stages of the mosquito, from egg to adulthood. 

Add agent predation behavior. In reality, female mosquitoes need feeding on blood, which they need to mature their eggs. This feature embeds a full life cycle in the model. This could incorporate additional factors that decrease mosquito populations such as bats and spray treatments.

Add and track a variety of diseases such as Zika virus, West Nile Virus, Malaria, and Dengue Fever.

Modified layouts including building structures and different water sources to closer resemble a target environment of study.


## NETLOGO FEATURES

The code demonstrates many examples of sprouting turtles from a patch.

The code also demonstrates the use of the watch, subject, and reset-perspective primitives in conjunction with mouse-down and mouse coordinates to automatically pause model and allow user to select and drag a turtle.

The model shows how to leverage the in-cone reporter to create a field of vision then uses max-one-of and face to find the closest water patch. 


## RELATED MODELS

Ants
Moths
Line of sight 
Mouse drag one example


## CREDITS AND REFERENCES

https://github.com/seancoogan/netlogo-mosquito
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
