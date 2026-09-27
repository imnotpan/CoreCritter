class_name Wallet
extends Node

signal coins_changed(coins: int)

var coins := 0


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)


func can_spend(amount: int) -> bool:
	return amount >= 0 and coins >= amount


func spend(amount: int) -> bool:
	if not can_spend(amount):
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true
