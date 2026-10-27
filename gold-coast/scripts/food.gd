class_name Food
extends Resource
## One dish on a menu: what it's called, what it costs, and how filling it is.
## Shops keep a list of these, which you can edit in the Inspector.

## The dish's name, like "Waakye".
@export var title := "Waakye"
## A few words about it, shown under the name on the menu.
@export var description := ""
## What it costs, in pesewas (2500 = GH₵25.00).
@export var price := 2500
## How much hunger it gives back.
@export_range(0.0, 100.0) var hunger := 45.0
## How long it takes to eat, in game minutes.
@export var minutes := 30.0
## Served in a bowl (like waakye) or not (like a sachet of water).
@export var in_bowl := true
## The color of the food in the bowl.
@export var color := Palette.ColorName.WAAKYE_BROWN
## The color of what's on top (stew, fish, a ball of fufu...).
@export var topping := Palette.ColorName.SHITO_BLACK
