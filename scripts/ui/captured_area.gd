extends Control

# 持ち駒表示エリア

@export var white_area_rect: Rect2 = Rect2(10, 10, 780, 80)
@export var black_area_rect: Rect2 = Rect2(10, 810, 780, 80)

var piece_spacing: int = 60
var highlighted_piece = null

signal captured_piece_selected(player, index)

func _ready() -> void:
	pass

func _draw() -> void:
	# 白の持ち駒エリア
	draw_rect(white_area_rect, Color(0.2, 0.2, 0.2, 0.3))
	
	# 黒の持ち駒エリア
	draw_rect(black_area_rect, Color(0.2, 0.2, 0.2, 0.3))
	
	# ハイライト表示
	if highlighted_piece:
		var player = highlighted_piece[0]
		var index = highlighted_piece[1]
		var highlight_rect = _get_piece_rect(player, index)
		draw_rect(highlight_rect, Color(0.3, 0.7, 0.3, 0.5))

func update_display(captured_pieces: Dictionary) -> void:
	# 白の持ち駒表示
	_draw_captured_pieces(Globals.Player.WHITE, captured_pieces[Globals.Player.WHITE], white_area_rect)
	
	# 黒の持ち駒表示
	_draw_captured_pieces(Globals.Player.BLACK, captured_pieces[Globals.Player.BLACK], black_area_rect)
	
	# 再描画
	queue_redraw()

func _draw_captured_pieces(player: int, pieces: Array, area_rect: Rect2) -> void:
	# 既存の駒スプライトを削除
	for child in get_children():
		if child.is_in_group("captured_" + str(player)):
			remove_child(child)
			child.queue_free()
	
	# 新しい駒スプライトを追加
	for i in range(pieces.size()):
		var piece = pieces[i]
		var sprite = Sprite2D.new()
		
		var piece_name = ""
		match piece.type:
			Globals.PieceType.PAWN:
				piece_name = "pawn"
			Globals.PieceType.ROOK:
				piece_name = "rook"
			Globals.PieceType.KNIGHT:
				piece_name = "knight"
			Globals.PieceType.BISHOP:
				piece_name = "bishop"
			Globals.PieceType.QUEEN:
				piece_name = "queen"
			Globals.PieceType.KING:
				piece_name = "king"
		
		var texture_path = "res://assets/pieces/white_" + piece_name + ".png" if player == Globals.Player.WHITE else "res://assets/pieces/black_" + piece_name + ".png"
		var texture = null
		
		# テクスチャファイルが存在するか確認
		if FileAccess.file_exists(texture_path):
			texture = load(texture_path)
		else:
			# デフォルトの代替テクスチャを作成（円形）
			var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			image.fill(Color.WHITE if player == Globals.Player.WHITE else Color.BLACK)
			
			# 円を描く
			for x in range(64):
				for y in range(64):
					var dist = Vector2(x - 32, y - 32).length()
					if dist > 30:
						image.set_pixel(x, y, Color(0, 0, 0, 0))
			
			# テクスチャとして設定
			var img_texture = ImageTexture.create_from_image(image)
			texture = img_texture
		
		if texture:
			sprite.texture = texture
			sprite.scale = Vector2(0.8, 0.8)  # 少し小さめに表示
			
			# 位置調整
			sprite.position = Vector2(
				area_rect.position.x + 40 + i * piece_spacing,
				area_rect.position.y + area_rect.size.y / 2
			)
			
			sprite.add_to_group("captured_" + str(player))
			add_child(sprite)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos = event.position
		
		# 白の持ち駒エリア内のクリック
		if white_area_rect.has_point(pos):
			var index = _get_piece_index_at_position(Globals.Player.WHITE, pos)
			if index >= 0:
				highlight_piece(Globals.Player.WHITE, index)
				captured_piece_selected.emit(Globals.Player.WHITE, index)
		
		# 黒の持ち駒エリア内のクリック
		elif black_area_rect.has_point(pos):
			var index = _get_piece_index_at_position(Globals.Player.BLACK, pos)
			if index >= 0:
				highlight_piece(Globals.Player.BLACK, index)
				captured_piece_selected.emit(Globals.Player.BLACK, index)

func _get_piece_index_at_position(player: int, pos: Vector2) -> int:
	var area_rect = white_area_rect if player == Globals.Player.WHITE else black_area_rect
	
	if not area_rect.has_point(pos):
		return -1
	
	var x_offset = pos.x - area_rect.position.x - 40
	if x_offset < 0:
		return -1
	
	var index = int(x_offset / piece_spacing)
	var piece_count = _count_pieces_in_group("captured_" + str(player))
	
	if index >= 0 and index < piece_count:
		return index
	
	return -1

func _count_pieces_in_group(group_name: String) -> int:
	var count = 0
	for child in get_children():
		if child.is_in_group(group_name):
			count += 1
	return count

func get_piece_index_at(pos: Vector2) -> int:
	# 白の持ち駒エリア内のクリック
	if white_area_rect.has_point(pos):
		return _get_piece_index_at_position(Globals.Player.WHITE, pos)
	
	# 黒の持ち駒エリア内のクリック
	elif black_area_rect.has_point(pos):
		return _get_piece_index_at_position(Globals.Player.BLACK, pos)
	
	return -1

func highlight_piece(player: int, index: int) -> void:
	highlighted_piece = [player, index]
	queue_redraw()

func clear_selection() -> void:
	highlighted_piece = null
	queue_redraw()

func _get_piece_rect(player: int, index: int) -> Rect2:
	var area_rect = white_area_rect if player == Globals.Player.WHITE else black_area_rect
	var x = area_rect.position.x + 10 + index * piece_spacing
	var y = area_rect.position.y + 10
	return Rect2(x, y, piece_spacing - 10, area_rect.size.y - 20)