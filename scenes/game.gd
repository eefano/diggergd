extends Control

signal end_game()
signal winner()
signal loser()

var levelnumber:int
var levelmap:TileMap
var playerpos:Vector2i
var totbonus:int
var lives:int
var hasmoved:bool
var diestate:bool
var winstate:bool
var nextmove:Vector2i
var elapse:int

const VBONUS:Vector2i = Vector2i(0,0)
const VDOORCL:Vector2i = Vector2i(0,1)
const VEMPTY:Vector2i = Vector2i(0,2)
const VGREENY:Vector2i = Vector2i(0,3)
const VMYHERO:Vector2i = Vector2i(0,4)
const VDOOROP:Vector2i = Vector2i(0,5)
const VSTONE:Vector2i = Vector2i(0,6)
const VWALL:Vector2i = Vector2i(0,7)

func settotbonus(n:int):
	totbonus = n
	$Left.text = "Left %3d" % n 
	
func setlives(n:int):
	lives = n
	$Lives.text = "Lives %d" % n

func setlevelnumber(n:int):
	levelnumber = n
	$Level.text = "Level %2d" % (n+1)
		
func restartlevel():
	
	if levelmap!=null:
		remove_child(levelmap)
		
	levelmap = load("res://scenes/level%02d.tscn" % levelnumber).instantiate();
	add_child(levelmap);
	playerpos = levelmap.get_used_cells_by_id(0,-1,VMYHERO)[0]
	settotbonus(levelmap.get_used_cells_by_id(0,-1,VBONUS).size())
	hasmoved = false
	diestate = false
	winstate = false
	nextmove = Vector2i.ZERO
	
func getelapsed():
	return (Time.get_ticks_msec() - elapse) / 1000
	
func settimerlabel():
	var t:int = getelapsed()
	$Elapsed.text = "%02d:%02d" % [ t/60 , t%60 ]

func init():
	elapse = Time.get_ticks_msec()
	settimerlabel()
	setlives(9)
	setlevelnumber(0)
	restartlevel()
	
func _ready():
	elapse = Time.get_ticks_msec()
	
func _on_timer_timeout():
	settimerlabel()

func movement(event):
	if event.is_action_pressed("ui_up"):
		nextmove = Vector2i.UP
	if event.is_action_pressed("ui_down"):
		nextmove = Vector2i.DOWN
	if event.is_action_pressed("ui_left"):
		nextmove = Vector2i.LEFT
	if event.is_action_pressed("ui_right"):
		nextmove = Vector2i.RIGHT

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		end_game.emit()
		return
		
	if event.is_action_pressed("ui_select"):
		if winstate:
			if levelnumber==15:
				winner.emit(getelapsed())
				return
			else:
				setlevelnumber(levelnumber+1)
		else:
			if not diestate:
				diestate = true
				$DeadFall.play()
			if lives==1:
				loser.emit()
				return
			else:
				setlives(lives-1)
		restartlevel()
		return
	
	# vital to get movement signals between physics process (that runs at 10fps)	
	movement(event)


func getatlas(newpos):
	return levelmap.get_cell_atlas_coords(0, newpos)
		
func _physics_process(delta):
	settimerlabel()
	movement(Input)
			
	if diestate or winstate:
		return
	
	if hasmoved:
		for c in levelmap.get_used_cells_by_id(0,-1,VSTONE) + levelmap.get_used_cells_by_id(0,-1,VBONUS):
			var newpos = c+Vector2i.DOWN
			var under = getatlas(newpos) 
			if under==VGREENY or under==VMYHERO: # don't slide under that
				newpos = null
			elif under!=VEMPTY:
				newpos = c+Vector2i.LEFT
				if getatlas(newpos)!=VEMPTY or getatlas(newpos+Vector2i.DOWN)!=VEMPTY:
					newpos = c+Vector2i.RIGHT
					if getatlas(newpos)!=VEMPTY or getatlas(newpos+Vector2i.DOWN)!=VEMPTY:
						newpos = null
			
			if newpos!=null:
				var sourceid = levelmap.get_cell_source_id(0,c)
				var ctype = getatlas(c)
				levelmap.set_cell(0, newpos, sourceid, ctype)
				levelmap.set_cell(0, c, sourceid, VEMPTY)
				var undpos = newpos+Vector2i.DOWN
				under = getatlas(undpos)
				if under==VMYHERO:
					var alt = levelmap.get_cell_alternative_tile(0,undpos)
					alt |= TileSetAtlasSource.TRANSFORM_TRANSPOSE
					levelmap.set_cell(0,undpos,sourceid,VMYHERO,alt)
					diestate = true
					$DeadFall.play()
					nextmove = Vector2i.ZERO
				if under!=VEMPTY and ctype==VSTONE:
					$StonFall.play()
				if under!=VEMPTY and ctype==VBONUS:
					$BonuFall.play()
				

	if nextmove != Vector2i.ZERO:
		var movec = nextmove
		nextmove = Vector2i.ZERO
		hasmoved = true
		var newpos = playerpos + movec
		var sourceid = levelmap.get_cell_source_id(0,newpos)
		if sourceid != -1:
			
			var walk = false
			
			match getatlas(newpos):
				VBONUS:
					walk = true
					settotbonus(totbonus-1)
					$GotaBonu.play()
					if totbonus==0:
						$OpenDoor.play()
						for c in levelmap.get_used_cells_by_id(0,-1,VDOORCL):
							levelmap.set_cell(0, c, sourceid, VDOOROP)
				VEMPTY:
					walk = true
				VGREENY:
					walk = true
				VDOOROP:
					walk = true
					winstate = true
					$ExitLevl.play()
				VSTONE:
					var newstone = playerpos+movec*2
					if movec.y==0 and getatlas(newstone)==VEMPTY:
						walk = true
						levelmap.set_cell(0,newstone, sourceid, VSTONE)
						$PushPull.play()
					
			if walk:
				levelmap.set_cell(0, playerpos, levelmap.get_cell_source_id(0,playerpos), VEMPTY)
				if not winstate:
					levelmap.set_cell(0, newpos, sourceid, VMYHERO)
				playerpos = newpos

