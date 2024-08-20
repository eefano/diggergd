extends Control

signal start_game()

signal select
signal cancel

func _ready():
	pass 

func _input(event):
	if event.is_action_pressed("ui_select"):
		select.emit()
	if event.is_action_pressed("ui_cancel"):
		cancel.emit()
