class_name Wallet
extends Node

signal coins_changed(coins: int)

var coins := 0


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
