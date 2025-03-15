extends Control

# ゲーム終了ダイアログ

func _ready() -> void:
	# 初期状態では非表示
	visible = false
	
	# ボタンにシグナルを接続
	$VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)
	$VBoxContainer/PlayAgainButton.pressed.connect(_on_play_again_button_pressed)

func show_winner(winner: int) -> void:
	$VBoxContainer/ResultLabel.text = Globals.get_player_name(winner) + " wins!"
	visible = true

func show_draw() -> void:
	$VBoxContainer/ResultLabel.text = "Draw!"
	visible = true

func _on_main_menu_button_pressed() -> void:
	# メインメニューに戻る
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_play_again_button_pressed() -> void:
	# 同じ設定で再プレイ
	get_tree().reload_current_scene()