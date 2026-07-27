extends Node

enum State { PLAYING, PC_SCREEN , PAUSED }

var current: State = State.PLAYING

func can_player_move() -> bool:
	return current == State.PLAYING
