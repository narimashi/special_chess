extends Control

# ポーンの昇格選択ダイアログ

signal promotion_selected(promotion_type)

var piece
var target_pos
var player_color

func _ready() -> void:
	# 初期状態では非表示
	visible = false
	
	# ボタンにシグナルを接続
	$VBoxContainer/HBoxContainer/QueenButton.pressed.connect(_on_queen_selected)
	$VBoxContainer/HBoxContainer/RookButton.pressed.connect(_on_rook_selected)
	$VBoxContainer/HBoxContainer/BishopButton.pressed.connect(_on_bishop_selected)
	$VBoxContainer/HBoxContainer/KnightButton.pressed.connect(_on_knight_selected)

func show_for_piece(target_piece, to_position: Vector2) -> void:
	piece = target_piece
	target_pos = to_position
	player_color = piece.player
	
	# 画像を適切なプレイヤーカラーに設定
	var color_prefix = "white" if player_color == Globals.Player.WHITE else "black"
	
	var queen_path = "res://assets/pieces/" + color_prefix + "_queen.png"
	var rook_path = "res://assets/pieces/" + color_prefix + "_rook.png"
	var bishop_path = "res://assets/pieces/" + color_prefix + "_bishop.png"
	var knight_path = "res://assets/pieces/" + color_prefix + "_knight.png"
	
	# テクスチャファイルの存在確認とフォールバック処理
	_set_button_texture($VBoxContainer/HBoxContainer/QueenButton, queen_path, "Q")
	_set_button_texture($VBoxContainer/HBoxContainer/RookButton, rook_path, "R")
	_set_button_texture($VBoxContainer/HBoxContainer/BishopButton, bishop_path, "B")
	_set_button_texture($VBoxContainer/HBoxContainer/KnightButton, knight_path, "N")
	
	# システムフォントを使用するように設定
	_ensure_default_font($VBoxContainer/Label)
	
	# ダイアログを表示
	visible = true
	
	# モーダルモードに設定（ダイアログ外のクリックを無効化）
	set_process_input(true)

# ボタンにテクスチャを設定（なければフォールバックテキストを使用）
func _set_button_texture(button: Button, texture_path: String, fallback_text: String) -> void:
	if button == null:
		return
		
	if FileAccess.file_exists(texture_path):
		button.icon = load(texture_path)
		button.text = ""
	else:
		button.icon = null
		button.text = fallback_text
		# フォントサイズを調整
		button.add_theme_font_size_override("font_size", 24)

# デフォルトフォントを確保
func _ensure_default_font(label: Label) -> void:
	if label:
		# すでにテーマがある場合はそれを使用、なければ新規作成
		var theme = label.get_theme() if label.get_theme() else Theme.new()
		label.theme = theme

func _on_queen_selected() -> void:
	_handle_selection(Globals.PieceType.QUEEN)

func _on_rook_selected() -> void:
	_handle_selection(Globals.PieceType.ROOK)

func _on_bishop_selected() -> void:
	_handle_selection(Globals.PieceType.BISHOP)

func _on_knight_selected() -> void:
	_handle_selection(Globals.PieceType.KNIGHT)

func _handle_selection(promotion_type: int) -> void:
	# 非表示に戻す
	visible = false
	set_process_input(false)
	
	# 選択結果を通知
	promotion_selected.emit(promotion_type)

func _input(event: InputEvent) -> void:
	# モーダルモード中は他のクリックを無視
	if visible and event is InputEventMouseButton and event.pressed:
		var rect = get_rect()
		if not rect.has_point(event.position):
			get_viewport().set_input_as_handled()
