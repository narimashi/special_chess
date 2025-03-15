extends Control

# メインメニュー画面

func _ready() -> void:
	# ボタンイベントの接続
	if has_node("VBoxContainer/PlayButton"):
		$VBoxContainer/PlayButton.pressed.connect(_on_play_button_pressed)
	if has_node("VBoxContainer/SettingsButton"):
		$VBoxContainer/SettingsButton.pressed.connect(_on_settings_button_pressed)
	if has_node("VBoxContainer/QuitButton"):
		$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)
	
	# 設定ダイアログのシグナル接続
	if has_node("SettingsDialog/VBoxContainer/SoundCheck"):
		$SettingsDialog/VBoxContainer/SoundCheck.toggled.connect(_on_sound_toggled)
	if has_node("SettingsDialog/VBoxContainer/MusicCheck"):
		$SettingsDialog/VBoxContainer/MusicCheck.toggled.connect(_on_music_toggled)
	if has_node("SettingsDialog/VBoxContainer/DifficultyOptions"):
		$SettingsDialog/VBoxContainer/DifficultyOptions.item_selected.connect(_on_difficulty_selected)
	
	# ラベルにデフォルトフォントを設定
	_setup_default_fonts()
	
	# 背景音楽の再生
	if Globals.music_enabled and has_node("BackgroundMusic"):
		if $BackgroundMusic.stream == null:
			# 開始音声ファイルをロード
			var audio_path = "res://assets/sounds/game_start.mp3"
			if FileAccess.file_exists(audio_path):
				$BackgroundMusic.stream = load(audio_path)
				$BackgroundMusic.play()
		else:
			$BackgroundMusic.play()

# デフォルトフォントをすべてのラベルに適用
func _setup_default_fonts() -> void:
	# シーン内のすべてのラベルとボタンにデフォルトフォントを設定
	var children = find_children("*", "Label")
	for child in children:
		var theme = Theme.new()
		child.theme = theme
	
	# ボタンのフォントも設定
	children = find_children("*", "Button")
	for child in children:
		var theme = Theme.new()
		child.theme = theme

func _on_play_button_pressed() -> void:
	# ゲームモード選択画面へ
	get_tree().change_scene_to_file("res://scenes/GameModeSelect.tscn")

func _on_settings_button_pressed() -> void:
	# 設定画面の表示
	# 現在の設定を反映
	$SettingsDialog/VBoxContainer/SoundCheck.button_pressed = Globals.sound_enabled
	$SettingsDialog/VBoxContainer/MusicCheck.button_pressed = Globals.music_enabled
	$SettingsDialog/VBoxContainer/DifficultyOptions.selected = Globals.current_difficulty
	
	$SettingsDialog.popup_centered()

func _on_quit_button_pressed() -> void:
	# ゲーム終了
	get_tree().quit()

# 設定変更時のコールバック
func _on_sound_toggled(enabled: bool) -> void:
	Globals.sound_enabled = enabled

func _on_music_toggled(enabled: bool) -> void:
	Globals.music_enabled = enabled
	if Globals.music_enabled:
		$BackgroundMusic.play()
	else:
		$BackgroundMusic.stop()

func _on_difficulty_selected(index: int) -> void:
	Globals.current_difficulty = index