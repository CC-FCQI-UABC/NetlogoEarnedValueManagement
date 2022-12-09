;;EXTENSIONS

extensions [ csv ]

;;INCLUDING A NETLOGO SOURCE FILES
__includes["EarnedValueManagement.nls"]

;;GLOBAL VARIABLES
globals [tasks-count fibonacci]

;;BREED DEFINITIONS
directed-link-breed [red-links red-link]
undirected-link-breed [blue-links blue-link]
breed [employees employee]
breed [tasks task]

;AGENT PROPERTIES DEF SECTION
employees-own [
  employee-number
  status
  role
  motivation
]

tasks-own [
  status
  task-number
  task-description
  priority
  project-code
  project-breakdown-code
  category sub-category
  planned-start
  planned-finish
  planned-hours
  complete-hours
  actual-hours
]


;;SETUP-SECTION
to setup
  clear-all
  setup-tasks
  setup-employees
  reset-ticks
end

to read-csv
  file-close-all ; close all open files

  if not file-exists? csv-file [
    user-message "No file exists!"
    stop
  ]

  file-open csv-file ; open the file with the tasks data

  if csv-file = "input/Sip-task-info.csv" [
    ; We'll read all the data in a single loop
    while [ not file-at-end? ] [
      ; here the CSV extension grabs a single line and puts the read data in a list
      let data csv:from-row file-read-line
      ; now we can use that list to create a tasks with the saved properties
      create-tasks 1 [
        set color red
        set shape "square"
        set tasks-count 0
        set status "to-do"
        set task-number item 0 data
        set task-description item 1 data
        set priority item 2 data
        set project-code item 7 data
        set project-breakdown-code item 8 data
        set category item 9 data
        set sub-category item 10 data
        set planned-start "01/01/2022"
        set planned-finish "01/02/2022"
        set planned-hours round item 11 data
        set complete-hours 0
        set actual-hours 0]
    ]
  ]

    if csv-file = "input/Software-Development-Plan.csv" [
    ; We'll read all the data in a single loop
    while [ not file-at-end? ] [
      ; here the CSV extension grabs a single line and puts the read data in a list
      let data csv:from-row file-read-line
      ; now we can use that list to create a tasks with the saved properties
      if item 5 data != ""[ ;if the retived task have an assigned team member, then create a task in the model.
        create-tasks 1 [
          set color red
          set shape "square"
          set tasks-count 0
          set status "to-do"
          set task-number item 2 data
          set task-description item 4 data
          set priority item 11 data
          set project-code 0
          set project-breakdown-code item 3 data
          set category 0
          set sub-category 0
          set planned-start item 8 data
          set planned-finish item 9 data
          set planned-hours item 10 data
          set complete-hours 0
          set actual-hours 0]
      ]
    ]
  ]

  file-close ; make sure to close the file
end

to setup-tasks
  ifelse load-file [
    read-csv
  ][
    create-tasks number-of-tasks [
      set color red
      set shape "square"
      set tasks-count 0
      set status "to-do"
      set task-number 100
      set task-description "task-description"
      set priority 0
      set project-code 0
      set project-breakdown-code 0
      set category 0
      set sub-category 0
      set planned-start "01/01/2022"
      set planned-finish "01/02/2022"
      set planned-hours item random 10 [1 2 3 5 8 13 21 34 55 89 144 233]
      set complete-hours 0
      set actual-hours 0]
  ]

  set tasks-count count tasks - 1
  tasks-board-update
end

to setup-employees
  create-employees employees-number [
    setxy random-xcor (random 16) - 16
    set shape "person"
    set employee-number random 10000
    set status "Active"
    set role "Developer"
    set motivation 1.0
  ]
  create-team
end

;;EXECUTION SECTION
to go
  processing-the-tasks
  if count tasks with [color = green] = count tasks [stop]
  tick
end

;;PROCEDURES SECTION
to processing-the-tasks
  the-employee-picks-tasks-from-the-to-do-backlog
  the-employee-moves-assignments-to-the-in-progress-queue
  the-employee-achieves-and-moves-tasks-to-the-done-cue

end

to the-employee-picks-tasks-from-the-to-do-backlog
  foreach sort employees[
    the-employee -> ask the-employee [
      if count out-link-neighbors with [status = "in-progress"] < assigned-tasks-employee [
        if tasks-count >= 0 [
          create-link-with task tasks-count
          set tasks-count tasks-count - 1
        ]
      ]
    ]
  ]
  tasks-board-update
end

to the-employee-moves-assignments-to-the-in-progress-queue
  ask employees [
    ask out-link-neighbors with [status = "to-do"][
        set color yellow
        set status "in-progress"
    ]
  ]
  tasks-board-update
end

to the-employee-achieves-and-moves-tasks-to-the-done-cue
  ask employees [
    ask out-link-neighbors with [status = "in-progress"][
      ifelse complete-hours >= planned-hours[
        set color green
        set status "done"
      ][
        if (random 100 >= probability-of-delay * 100    )[
          set complete-hours complete-hours + 1
        ]
        if (random 100 >= probability-of-advance * 100    )[
          set actual-hours actual-hours + 1
        ]
      ]
    ]
  ]
  tasks-board-update
end

;; forms a link between all employees
to create-team
  ask employees
  [
    create-links-with other employees
    [
      set color blue
    ]
  ]
end

; procedure to write some turtle properties to a file
to write-tasks-to-csv
  ; we use the `of` primitive to make a list of lists and then
  ; use the csv extension to write that list of lists to a file.
  ; csv:to-file "tasks.csv" [ (list task-number task-description planned-start planned-finish planned-hours (word ((complete-hours / planned-hours) * 100) "%") actual-hours) ] of tasks
  csv:to-file "output/tasks.csv" [ (list task-number project-breakdown-code task-description planned-start planned-finish planned-hours (complete-hours / planned-hours) actual-hours) ] of tasks
end

; procedure to write some turtle properties to a file
to write-employees-to-csv
  ; we use the `of` primitive to make a list of lists and then
  ; use the csv extension to write that list of lists to a file.
  csv:to-file "output/employees.csv" [ (list  employee-number status role motivation) ] of employees
end

to tasks-board-update
  let x -16
  let y 0
  foreach sort tasks with [status = "to-do"][
    the-task -> ask the-task [
      setxy x y

      ifelse x >= -6
      [set x -16
      set y y + 1]
      [set x x + 1]

      if y >= 17
      [set y 0]
    ]
  ]

  set x -5
  set y 0
  foreach sort tasks with [status = "in-progress"][
    the-task -> ask the-task [
      setxy x y

      ifelse x >= 5
      [set x -5
      set y y + 1]
      [set x x + 1]

      if y >= 17
      [set y 0]
    ]
  ]

  set x 6
  set y 0
  foreach sort tasks with [status = "done"][
    the-task -> ask the-task [
      setxy x y

      ifelse x >= 16
      [set x 6
      set y y + 1]
      [set x x + 1]

      if y >= 17
      [set y 0]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
279
10
734
466
-1
-1
13.55
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
0
186
95
219
setup
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
190
186
276
219
go
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
182
268
275
313
Done
count tasks with [status = \"done\"]
17
1
11

PLOT
0
316
275
465
Burndown chart
time
tasks
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"ToDo" 1.0 0 -2674135 true "" "plot count tasks with [status = \"to-do\"]"
"InProgress" 1.0 0 -13345367 true "" "plot count tasks with [status = \"in-progress\"]"
"Done" 1.0 0 -10899396 true "" "plot count tasks with [status = \"done\"]"

SLIDER
0
10
275
43
employees-number
employees-number
1
100
3.0
1
1
NIL
HORIZONTAL

BUTTON
96
186
189
219
step-go
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
0
44
275
77
number-of-tasks
number-of-tasks
1
200
187.0
1
1
NIL
HORIZONTAL

MONITOR
93
268
180
313
In progress
count tasks with [status = \"in-progress\"]
17
1
11

MONITOR
0
268
91
313
To do
count tasks with [status = \"to-do\"]
17
1
11

PLOT
738
102
1032
267
Earned value 
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"PV%" 1.0 0 -10899396 true "" "plot PV2%"
"AC%" 1.0 0 -2674135 true "" "plot AC%"
"EV%" 1.0 0 -13345367 true "" "plot EV%"

MONITOR
738
10
883
55
Planned Value
PV
17
1
11

MONITOR
738
56
831
101
Earned Value
EV
17
1
11

MONITOR
884
10
1032
55
Actual Cost
AC
17
1
11

MONITOR
0
221
276
266
Budget at Completion
BAC
17
1
11

MONITOR
832
56
941
101
Schedule Variance
SV
17
1
11

MONITOR
942
56
1032
101
Cost Variance
CV
17
1
11

MONITOR
1035
10
1308
55
Schedule Performance Index
SPI
17
1
11

MONITOR
1035
56
1308
101
Cost Performance Index
CPI
17
1
11

MONITOR
738
270
1032
315
To Complete Performance Index
TCPI
17
1
11

PLOT
1035
102
1308
267
Performance
NIL
NIL
0.0
10.0
-0.0
1.5
true
true
"" ""
PENS
"SPI" 1.0 0 -13345367 true "" "plot SPI"
"CPI" 1.0 0 -2674135 true "" "plot CPI"
"1.0" 1.0 0 -3026479 false "" "plot 1"

PLOT
738
317
1032
467
To Complete Performance Index
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"TCPI" 1.0 0 -16777216 true "" "plot TCPI"

SLIDER
0
79
275
112
probability-of-delay
probability-of-delay
0
1
0.2
0.01
1
NIL
HORIZONTAL

MONITOR
738
468
894
513
Estimate at Completion
EAC1
17
1
11

MONITOR
896
468
1032
513
Estimate to Complete
ETC
17
1
11

MONITOR
1036
468
1171
513
Variance at Completion
VAC
17
1
11

MONITOR
1035
270
1309
315
Cost Performance Index at Conclusion
CPIAC
17
1
11

PLOT
1036
516
1312
666
Time Estimate at Completion
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
"EACt" 1.0 0 -16777216 true "" "plot EACt"
"Ticks" 1.0 0 -7500403 true "" "plot ticks"

MONITOR
1172
468
1311
513
Time Estimate at Completion
EACt
17
1
11

PLOT
737
515
1032
666
Estimations
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
"EAC" 1.0 0 -16777216 true "" "plot EAC1"
"ETC" 1.0 0 -7500403 true "" "plot ETC"

MONITOR
458
470
732
515
Performance Measurement Baseline Duration
PMB-Duration
17
1
11

SLIDER
0
149
275
182
assigned-tasks-employee
assigned-tasks-employee
1
10
8.0
1
1
NIL
HORIZONTAL

CHOOSER
1
470
286
515
csv-file
csv-file
"input/Sip-task-info.csv" "input/Software-Development-Plan.csv"
1

SWITCH
0
516
109
549
load-file
load-file
0
1
-1000

SLIDER
0
114
275
147
probability-of-advance
probability-of-advance
0
1
0.2
0.01
1
NIL
HORIZONTAL

BUTTON
0
551
277
584
Write tasks to tasks.csv
write-tasks-to-csv
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1035
316
1310
466
Cost Performance Index at Conclusion
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"CPIAC" 1.0 0 -16777216 true "" "plot CPIAC"

PLOT
458
516
732
666
Performance Measurement Baseline Duration
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"PMB-duration" 1.0 0 -16777216 true "" "plot PMB-Duration"

BUTTON
0
586
277
619
Write employees to employees.csv
write-employees-to-csv
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

The model aims to illustrate how Earned Vaue Management (EVM) provides an approach to measure a project's performance by comparing its actual progress against the planned one, allowing it to evaluate trends to formulate forecasts. The instance performs a project execution and calculates the EVM performance indexes according to a Performance Measurement Baseline (PMB), which integrates the description of the work to do (scope), the deadlines for its execution (schedule), and the calculation of its costs and the resources required for its implementation (cost). 

Specifically, we are addressing the following questions: How does the risk of execution delay or advance impact cost and schedule performance? How do the players' number or individual work capacity impact cost and schedule estimations to finish? Regardless of why workers cause delays or produce overruns in their assignments, does EVM assess delivery performance and help make objective decisions? 

To consider our model realistic enough for its purpose, we use the following patterns: The model addresses classic problems of Project Management (PM). It plays the typical task board where workers are assigned to complete a task backlog in project performance. Workers could delay or advance in the task execution, and we calculate the performance using the PMI-recommended Earned Value. 


## HOW IT WORKS
The model includes the following entities: task and employee. The workspaces and the task board are spatial and temporal resolution and extent.

In the model, agents represent employees executing tasks in a simple, agile production system. Each agent takes a job from the backlog and performs it in the set time. The interface displays employees and tasks on a Kanban-like task board. To-do tasks are in the red card column, jobs in progress are in the yellow card column, and completed tasks are in the green card column.

The most critical processes of the model, which are repeated every time step, are: firstly, the employee picks tasks from the to-do backlog. Then the employee moves assignments to the in-progress queue. Finally, the employee achieves and carries tasks to the done cue.

The most important design concepts of the model are a task backlog, a task board, players (or employees), a cost and schedule plan, and performance metrics.

  1. The task backlog is a task backlog (to-do column) that requires individuals to complete it. The task board is task states portrayed on a task board to visualize the project's advancement.

  2. The players or employees must take as many as permitted tasks from the "to-do" queue and deliver them to the "done" cue in the panel. While a player is working on an assignment, he must keep the assignment tag in the "in-progress" column.

  3. The cost and schedule plan has a task-planned cost in hours and start-finish time, but the worker could delay or advance in completing the job, or environmental situations could increase and decrease the final cost.
  
  4. The performance metrics are the Earned Value Management metrics that estimate the project performance.


### Earned Value Management (EVM) metrics

We evaluate the system's efficiency using the Earned Value Measures (EVM).

EVM consists of the following primary and derived data elements. Each data point value is based on the time or date an EVM measure is performed on the project.

#### Main values

  * Planned Value, PV.
  * Earned Value, EV.
  * Actual Cost, AC.
  * Budget at Completion, BAC.

Percentages

  * PV% = PV / BAC
  * EV% = EV / BAC
  * AC% = AC / BAC

#### Variations

Schedule Variance, SV. 

  * SV = EV – PV

Cost Variance, CV. 

  * CV = EV – AC

  * SV% = SV / PV
  * CV% = CV / EV

#### Performance indexes

Schedule Performance Index, SPI. 

  * SPI = EV / PV

Cost Performance Index, CPI. 

  * CPI = EV /AC

To Complete Performance Index, TCPI. 

  * TCPI = (BAC – EV) / (BAC – AC).

#### Forecasting

Estimate at Completion, EAC. 

  * EAC = BAC – SV
  * EAC = BAC / CPI
  * EAC = BAC / (CPI * SPI)
  * EAC = AC + EAC = AC + New estimate for remaining work.

Estimate to Complete, ETC.
 
  * ETC = EAC – AC

Variance at Completion, VAC. 

  * VAC = BAC – EAC
  * VAC% = VAC / BAC

Cost Performance Index at Conclusion, CPIAC. 

  * CPIAC = BAC / EAC

## HOW TO USE IT

### Setup

  1. First, establish the number of employees involved and the number of tasks to perform on the project.
  2. Second, the setup procedure will generate the number of tasks selected with random units of effort with values between 1 and 10 and the desired set of employees.
  3. Third, establish the probability that a task will be late and the probability that it will be ahead. For an ideal scenario, the chance is zero in both cases.
  4. Finally, decide how many tasks each worker will be able to execute simultaneously. The budget at completion is the sum of all the story points or units of effort defined for each job.


### Running the model

1. Run the simulation step by step or in continue running.
2. On the fly, alter the values of probability-of-delay, probability-of-advance, or assigned-tasks-employee to see the consequences on the burndown chart and system state.

### After finishing simulation

1. Review the outcomes (burndown chart and EVM metrics).
2. Download tasks and employees' status to a CSV file if required. 
3. Use the EVM attached tools to compare results.


## THINGS TO NOTICE

Note that although the probabilities of delay and progress are equal, the project does not necessarily end with the estimated cost. Check the performance indexes values while simulation running if you change simulation condition in runtime.

## THINGS TO TRY

1. Try to create different configurations by imagining scenarios according to experience. 
2. Try loading sample tasks from the CSV files. One sample file comes from a software development project with 12299 tasks. The second file comes from a Microsoft Project sample file with a basic software development project template with 61 tasks. 

## EXTENDING THE MODEL

Loading the tasks from a CSV file demonstrates how we can import representative scenarios for analysis. The model can be extended by loading new files with sample tasks.

We could try adding human factors to the model. In that case, we could also add the decision-making attributes of individuals or some social factors resulting from their interactions and relationships.

Adding emergent behaviors resulting from the interaction of team members could add complexity to the model to explore the production system as a complex adaptive system.


## CREDITS AND REFERENCES

This model is an output of a research project supported by the internal research project fund of the Autonomous University of Baja California. Project registry: 300/6/C/11/22.

## LICENSE

Netlogo Earned Value Management v1.0.0 © 2022 by Manuel Castañón-Puga is licensed under CC BY 4.0. To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/
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
NetLogo 6.3.0
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
