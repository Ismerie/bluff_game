extends Node


func _ready() -> void:
	var create_button = get_node("../Control/CenterContainer/VBoxContainer/CreateButton")
	var join_button = get_node("../Control/CenterContainer/VBoxContainer/JoinButton")
	var settings_button = get_node("../Control/CenterContainer/VBoxContainer/SettingsButton")
	var quit_button = get_node("../Control/CenterContainer/VBoxContainer/QuitButton")

	create_button.pressed.connect(_on_play_pressed)
	join_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	print("Bouton Jouer cliqué")
	get_tree().change_scene_to_file("res://assets/scenes/Main.tscn")


func _on_settings_pressed() -> void:
	print("Bouton Paramètres cliqué")


func _on_quit_pressed() -> void:
	print("Bouton Quitter cliqué")
	get_tree().quit()
