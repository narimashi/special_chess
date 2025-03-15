extends Control

# ゲームモード選択画面

func _ready():
    # ボタンイベントの接続
    $VBoxContainer/BotButton.connect("pressed", self, "_on_bot_button_pressed")
    $VBoxContainer/FriendButton.connect("pressed", self, "_on_friend_button_pressed")
    $VBoxContainer/OnlineButton.connect("pressed", self, "_on_online_button_pressed")
    $VBoxContainer/TournamentButton.connect("pressed", self, "_on_tournament_button_pressed")
    $VBoxContainer/BackButton.connect("pressed", self, "_on_back_button_pressed")
    
    # オンラインモードと大会モードは初期リリースでは無効化
    $VBoxContainer/OnlineButton.disabled = true
    $VBoxContainer/TournamentButton.disabled = true

func _on_bot_button_pressed():
    # ボット対戦モードへ
    # 対戦相手の難易度を設定
    Globals.game_in_progress = true
    get_tree().change_scene("res://scenes/Game.tscn")

func _on_friend_button_pressed():
    # フレンド対戦モードへ（ローカル2人プレイ）
    $NotImplementedDialog.popup_centered()

func _on_online_button_pressed():
    # オンライン対戦モードへ（将来の実装）
    $NotImplementedDialog.popup_centered()

func _on_tournament_button_pressed():
    # 大会モードへ（将来の実装）
    $NotImplementedDialog.popup_centered()

func _on_back_button_pressed():
    # メインメニューへ戻る
    get_tree().change_scene("res://scenes/MainMenu.tscn")