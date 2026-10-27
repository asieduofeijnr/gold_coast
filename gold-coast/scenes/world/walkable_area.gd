extends NavigationRegion3D
## The area the player can walk around in, used for click-to-move. It's worked
## out when the game starts from everything solid (the ground, the buildings,
## and the billboard posts, which are in the "navigation_source" group), so
## moving or adding a building never leaves it out of date.


func _ready() -> void:
	bake_navigation_mesh(false) # false = work it out right now, not in the background
