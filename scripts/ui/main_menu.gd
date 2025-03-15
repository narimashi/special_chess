extends Control

# メインメニュー画面

func _ready():
    # ボタンイベントの接続
    $VBoxContainer/PlayButton.connect("pressed", self, "_on_play_button_pressed")
    $VBoxContainer/SettingsButton.connect("pressed", self, "_on_settings_button_pressed")
    $VBoxContainer/QuitButton.connect("pressed", self, "_on_quit_button_pressed")
    
    # 背景音楽の再生
    if Globals.music_enabled:
        $BackgroundMusic.play()

func _on_play_button_pressed():
    # ゲームモード選択画面へ
    get_tree().change_scene("res://scenes/GameModeSelect.tscn")

func _on_settings_button_pressed():
    # 設定画面の表示
    $SettingsDialog.popup_centered()

func _on_quit_button_pressed():
    # ゲーム終了
    get_tree().quit()

# 設定変更時のコールバック
func _on_setting_changed(setting_name, value):
    match setting_name:
        "sound":
            Globals.sound_enabled = value
        "music":
            Globals.music_enabled = value
            if Globals.music_enabled:
                $BackgroundMusic.play()
            else:
                $BackgroundMusic.stop()
        "difficulty":
            Globals.current_difficulty = value