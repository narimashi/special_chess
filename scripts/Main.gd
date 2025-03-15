extends Node

# メインシーン - ゲーム全体のエントリーポイント

func _ready() -> void:
	# グローバル設定の初期化
	_initialize_globals()
	
	# 必要なディレクトリの作成
	_ensure_directories()
	
	# 常に簡易メニューを使用する（既存のシーンファイルへの依存を避ける）
	_create_simple_menu()

func _initialize_globals() -> void:
	# グローバル設定の初期化処理
	pass

func _ensure_directories() -> void:
	# 必要なフォルダの存在確認と作成
	var required_dirs = ["res://assets", "res://assets/ui", "res://assets/sounds", "res://assets/pieces", "res://assets/cutins"]
	for dir in required_dirs:
		var d = DirAccess.open("res://")
		if d and not d.dir_exists(dir.replace("res://", "")):
			d.make_dir_recursive(dir.replace("res://", ""))
			print("Created directory: " + dir)

func _input(event: InputEvent) -> void:
	# ESCキーでゲーム終了（デバッグ用）
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

# 簡易メニューの作成
func _create_simple_menu() -> void:
	# 簡易メニューシーンを作成
	var simple_menu = Control.new()
	simple_menu.set_name("SimpleMenu")
	simple_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# 背景色の設定
	var background = ColorRect.new()
	background.set_name("Background")
	background.color = Color(0.1, 0.1, 0.3)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	simple_menu.call_deferred("add_child", background)
	
	var v_box = VBoxContainer.new()
	v_box.set_name("VBoxContainer")
	v_box.set_anchors_preset(Control.PRESET_CENTER)
	v_box.set_anchor(SIDE_LEFT, 0.5)
	v_box.set_anchor(SIDE_TOP, 0.5)
	v_box.set_anchor(SIDE_RIGHT, 0.5)
	v_box.set_anchor(SIDE_BOTTOM, 0.5)
	v_box.set_offset(SIDE_LEFT, -150)
	v_box.set_offset(SIDE_TOP, -150)
	v_box.set_offset(SIDE_RIGHT, 150)
	v_box.set_offset(SIDE_BOTTOM, 150)
	v_box.add_theme_constant_override("separation", 20)
	simple_menu.call_deferred("add_child", v_box)
	
	# ゲームタイトル
	var title = Label.new()
	title.set_name("TitleLabel")
	title.text = "Special Chess"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	v_box.call_deferred("add_child", title)
	
	# 開始ボタン
	var start_button = Button.new()
	start_button.set_name("StartButton")
	start_button.text = "Start Game"
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.call_deferred("connect", "pressed", _on_start_button_pressed)
	v_box.call_deferred("add_child", start_button)
	
	# 終了ボタン
	var quit_button = Button.new()
	quit_button.set_name("QuitButton")
	quit_button.text = "Quit"
	quit_button.add_theme_font_size_override("font_size", 24)
	quit_button.call_deferred("connect", "pressed", _on_quit_button_pressed)
	v_box.call_deferred("add_child", quit_button)
	
	# シーンをルートに設定
	call_deferred("_add_menu_to_tree", simple_menu)

# 遅延実行でメニューをシーンツリーに追加
func _add_menu_to_tree(menu_node: Node) -> void:
	get_tree().root.add_child(menu_node)

# 開始ボタンのイベントハンドラ
func _on_start_button_pressed() -> void:
	# 簡易ゲーム画面を直接作成する
	_create_simple_game()

# 簡易ゲーム画面を作成
func _create_simple_game() -> void:
	# 現在のシーンをクリア
	for child in get_tree().root.get_children():
		if child != self:  # Main自体は削除しない
			child.queue_free()
	
	# 簡易ゲーム画面の作成
	var simple_game = Node2D.new()
	simple_game.set_name("SimpleGame")
	
	# ゲーム背景
	var bg = ColorRect.new()
	bg.set_name("Background")
	bg.color = Color(0.2, 0.3, 0.4)
	bg.size = Vector2(800, 900)
	simple_game.call_deferred("add_child", bg)
	
	# メッセージラベル
	var label = Label.new()
	label.set_name("MessageLabel")
	label.text = "Simple Chess Game\n\nGame is running!\n\nPress ESC to return to menu"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(400, 450)
	label.size = Vector2(600, 200)
	label.anchors_preset = Control.PRESET_CENTER
	simple_game.call_deferred("add_child", label)
	
	# 戻るボタン
	var back_button = Button.new()
	back_button.set_name("BackButton")
	back_button.text = "Back to Menu"
	back_button.position = Vector2(350, 600)
	back_button.size = Vector2(200, 50)
	back_button.call_deferred("connect", "pressed", _on_back_button_pressed)
	simple_game.call_deferred("add_child", back_button)
	
	# シーンをルートに追加
	get_tree().root.call_deferred("add_child", simple_game)

# 戻るボタンのイベントハンドラ
func _on_back_button_pressed() -> void:
	# メインメニューに戻る
	for child in get_tree().root.get_children():
		if child.name == "SimpleGame":
			child.queue_free()
	
	# メインメニューを再作成
	_create_simple_menu()

# 終了ボタンのイベントハンドラ
func _on_quit_button_pressed() -> void:
	get_tree().quit()
