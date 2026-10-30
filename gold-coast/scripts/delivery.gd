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


## The load as it's written into a saved game.
func to_save() -> Dictionary:
	return {"goods": goods, "color": color, "place": place, "phone_place": phone_place, "receiver": receiver,
			"payer": payer, "pay": pay, "minutes": minutes, "due": due}


## A load read back from a saved game (see to_save()).
static func from_save(data: Dictionary) -> Delivery:
	var headload := Delivery.new()
	headload.goods = str(data.get("goods", ""))
	headload.color = int(data.get("color", Palette.ColorName.LIGHT_SOUP)) as Palette.ColorName
	headload.place = str(data.get("place", ""))
	headload.phone_place = str(data.get("phone_place", ""))
	headload.receiver = str(data.get("receiver", ""))
	headload.payer = str(data.get("payer", ""))
	headload.pay = int(data.get("pay", 0))
	headload.minutes = float(data.get("minutes", 30.0))
	headload.due = float(data.get("due", 0.0))
	return headload
