class_name Delivery
extends RefCounted
## A load a kayayo (a head porter) carries for someone: what's in the headpan,
## where it's going, what it pays, and when it's due.

## What's in the headpan, like "tomatoes".
var goods := ""
## The color of the goods in the headpan.
var color := Palette.ColorName.LIGHT_SOUP
## Where it's going: a DeliverySpot's place name, like "the Chop Bar".
var place := ""
## The same place, short enough for the phone's screen, like "CHOP BAR".
var phone_place := ""
## Who takes it there, like "Uncle Kofi".
var receiver := ""
## Who's paying for the carrying (shown in the phone's payment text).
var payer := ""
## The pay, in pesewas.
var pay := 0
## How long she has to deliver it, in game minutes.
var minutes := 30.0
## When it's due, as GameState.now() gives it. Set when she picks it up.
var due := 0.0
