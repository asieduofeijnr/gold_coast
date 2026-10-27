class_name Course
extends Resource
## A course at the training college, like the teaching certificate: what it
## costs, how many classes it takes, and what the certificate lets her do.

## Its id, which is also the name of the skill it gives (like "teaching").
@export var id := ""
## Its name on the college's board, like "Teaching Certificate".
@export var title := ""
## What the certificate lets her do, shown under its name on the board.
@export var description := ""
## Its name on the phone, short enough to fit (14 letters at most).
@export var phone_title := ""
## The fees, in pesewas, paid when she enrolls.
@export var fee := 0
## How many classes it takes, one a day.
@export var classes := 1
