class_name Format
## Turns numbers into text for the player.

const WEEKDAYS := ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]


## Money as Ghana cedis. `pesewas` is the amount in pesewas (100 = GH₵1):
## 10000 → "GH₵100.00", 650 → "GH₵6.50", 123456789 → "GH₵1,234,567.89".
static func cedis(pesewas: int) -> String:
	var amount := absi(pesewas)
	@warning_ignore("integer_division")
	var whole := str(amount / 100)
	# A comma between every group of three digits.
	var grouped := ""
	while whole.length() > 3:
		grouped = "," + whole.right(3) + grouped
		whole = whole.left(whole.length() - 3)
	var minus := "-" if pesewas < 0 else ""
	return "%sGH₵%s%s.%02d" % [minus, whole, grouped, amount % 100]


## A time of day, given in minutes since midnight, on a 24-hour clock:
## 420 → "07:00", 754.9 → "12:34".
static func clock(minutes: float) -> String:
	var whole := floori(minutes)
	@warning_ignore("integer_division")
	var hours := (whole / 60) % 24
	return "%02d:%02d" % [hours, whole % 60]


## The day of the week for a day number. Day 1 is a Monday: 1 → "MON", 8 → "MON".
static func weekday(day: int) -> String:
	return WEEKDAYS[posmod(day - 1, 7)]
