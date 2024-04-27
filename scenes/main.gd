extends Node

var menu
var intro
var game
var loser
var winner

# Called when the node enters the scene tree for the first time.
func _ready():
	menu = $Menu
	intro = $Intro
	game = $Game
	loser = $Loser
	winner = $Winner
	remove_child(intro)
	remove_child(game)
	remove_child(loser)
	remove_child(winner)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass
	
func startgame():
	call_deferred("add_child",game)
	game.init()
	
func _on_game_end_game():
	remove_child(game)
	call_deferred("add_child",menu)
	
func _on_intro_cancel():
	remove_child(intro)
	call_deferred("add_child",menu)
	
func _on_intro_select():
	remove_child(intro)
	startgame()

func _on_loser_cancel():
	remove_child(loser)
	call_deferred("add_child",menu)

func _on_loser_select():
	remove_child(loser)
	startgame()

func _on_winner_cancel():
	remove_child(winner)
	call_deferred("add_child",menu)

func _on_winner_select():
	remove_child(winner)
	startgame()

func _on_menu_cancel():
	if OS.get_name()!="Web": get_tree().quit()

func _on_menu_select():
	remove_child(menu)
	call_deferred("add_child",intro)

func _on_game_loser():
	remove_child(game)
	call_deferred("add_child",loser)

func _on_game_winner(t):
	remove_child(game)
	call_deferred("add_child",winner)
	winner.get_node("Elapsed").text = "%02d:%02d" % [ t/60 , t%60 ]
	
