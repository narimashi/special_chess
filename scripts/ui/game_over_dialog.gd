extends Control

# ゲーム終了ダイアログ

func _ready() -> void:
	# 初期状態では非表示
	visible = false
	
	# ボタンにシグナルを接続
	if has_node("VBoxContainer/MainMenuButton"):
		$VBoxContainer/MainMenuButton.pressed.connect(_on_main_menu_button_pressed)
	if has_node("VBoxContainer/PlayAgainButton"):
		$VBoxContainer/PlayAgainButton.pressed.connect(_on_play_again_button_pressed)
	
	# システムフォントを設定
	_setup_fonts()

func _setup_fonts() -> void:
	# ラベルのフォントサイズを設定
	if has_node("VBoxContainer/ResultLabel"):
		$VBoxContainer/ResultLabel.add_theme_font_size_override("font_size", 32)
	
	# ボタンのフォントサイズを設定
	if has_node("VBoxContainer/PlayAgainButton"):
		$VBoxContainer/PlayAgainButton.add_theme_font_size_override("font_size", 24)
	if has_node("VBoxContainer/MainMenuButton"):
		$VBoxContainer/MainMenuButton.add_theme_font_size_override("font_size", 24)

func show_winner(winner: int) -> void:
	$VBoxContainer/ResultLabel.text = Globals.get_player_name(winner) + " wins!"
	visible = true

func show_draw() -> void:
	$VBoxContainer/ResultLabel.text = "Draw!"
	visible = true

func _on_main_menu_button_pressed() -> void:
	# メインメニューに戻る
	if ResourceLoader.exists("res://scenes/MainMenu.tscn"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	else:
		# MainMenu.tscnがない場合は直接Main.tscnを読み込む
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_play_again_button_pressed() -> void:
	# 同じ設定で再プレイ
	get_tree().reload_current_scene()extends Control

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