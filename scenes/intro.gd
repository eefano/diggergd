extends Control

signal select
signal cancel

var loopy:int = 0
	
func _input(event):
	if event.is_action_pressed("ui_select"):
		select.emit()
	if event.is_action_pressed("ui_cancel"):
		cancel.emit()
	
func _physics_process(delta):
	
	for n in range(1,4):
		$TileMap.set_layer_enabled(n, n==((loopy/6) % 3 + 1))
		
	loopy+=1
	
