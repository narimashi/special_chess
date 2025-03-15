extends Control

# ゲーム終了ダイアログ

func _ready():
    # 初期状態では非表示
    visible = false
    
    # ボタンにシグナルを接続
    $VBoxContainer/MainMenuButton.connect("pressed", self, "_on_main_menu_button_pressed")
    $VBoxContainer/PlayAgainButton.connect("pressed", self, "_on_play_again_button_pressed")

func show_winner(winner):
    $VBoxContainer/ResultLabel.text = Globals.get_player_name(winner) + " wins!"
    visible = true

func show_draw():
    $VBoxContainer/ResultLabel.text = "Draw!"
    visible = true

func _on_main_menu_button_pressed():
    # メインメニューに戻る
    get_tree().change_scene("res://scenes/MainMenu.tscn")

func _on_play_again_button_pressed():
    # 同じ設定で再プレイ
    get_tree().reload_current_scene()