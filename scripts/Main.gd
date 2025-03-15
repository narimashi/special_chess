extends Node

# メインシーン - ゲーム全体のエントリーポイント

func _ready():
	# グローバル設定の初期化
	_initialize_globals()
	
	# メインメニューへ移動
	get_tree().change_scene("res://scenes/MainMenu.tscn")

func _initialize_globals():
	# グローバル設定の初期化処理
	pass

func _input(event):
	# ESCキーでゲーム終了（デバッグ用）
	if event is InputEventKey and event.pressed and event.scancode == KEY_ESCAPE:
		get_tree().quit()
