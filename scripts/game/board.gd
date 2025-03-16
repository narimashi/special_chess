extends Node2D

# チェスボードの表示を管理するクラス

# ボードのテーマカラー
var light_square_color: Color = Color(0.6, 0.4, 0.3)  # 明るい茶色
var dark_square_color: Color = Color(0.36, 0.2, 0.2)  # 深い茶色
var highlight_color: Color = Color(0.3, 0.7, 0.3, 0.5)  # 選択マスのハイライト
var move_indicator_color: Color = Color(0.2, 0.6, 0.9, 0.5)  # 移動可能マスの表示

# ボードの大きさと位置の設定
var board_size: int = 8  # 8x8 の標準的なチェスボード
var square_size: int = 80  # マスのサイズ（ピクセル）
var board_position: Vector2 = Vector2(60, 100)  # ボードの左上の位置

# 選択状態の管理
var highlight_position = null  # 選択されたマスの位置
var valid_move_positions = []  # 移動可能なマスの位置

func _ready() -> void:
	# ボードの初期位置を設定
	position = board_position
	
	# 初期描画
	queue_redraw()

func _draw() -> void:
	# ボードの描画
	_draw_board()
	
	# 選択マスのハイライト
	if highlight_position != null:
		_draw_highlight(highlight_position)
	
	# 移動可能マスの表示
	for pos in valid_move_positions:
		_draw_move_indicator(pos)

func _draw_board() -> void:
	# 8x8のチェスボードを描画
	for x in range(board_size):
		for y in range(board_size):
			var color = light_square_color if (x + y) % 2 == 0 else dark_square_color
			var rect = Rect2(x * square_size, y * square_size, square_size, square_size)
			draw_rect(rect, color)
	
	# ボード枠線
	var border_rect = Rect2(0, 0, board_size * square_size, board_size * square_size)
	draw_rect(border_rect, Color.BLACK, false, 2.0)
	
	# 座標ラベル（a-h, 1-8）
	_draw_coordinate_labels()

func _draw_coordinate_labels() -> void:
	var font = ThemeDB.fallback_font
	var font_size = 14
	var label_color = Color(0.9, 0.9, 0.9)  # 明るい色で見やすく
	
	# 横座標（a-h）
	for i in range(board_size):
		var label = char(97 + i)  # aから始まるアルファベット
		var pos = Vector2(i * square_size + square_size * 0.5, board_size * square_size + 15)
		draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, label_color)
	
	# 縦座標（1-8）、上から8,7,6...
	for i in range(board_size):
		var label = str(board_size - i)
		var pos = Vector2(-15, i * square_size + square_size * 0.5)
		draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, label_color)

func _draw_highlight(pos) -> void:
	# 選択マスのハイライト表示
	var rect = Rect2(pos.x * square_size, pos.y * square_size, square_size, square_size)
	draw_rect(rect, highlight_color)

func _draw_move_indicator(pos) -> void:
	# 移動可能マスの表示
	var center = Vector2(pos.x * square_size + square_size / 2, pos.y * square_size + square_size / 2)
	
	# 駒があるマスは枠線、空きマスは円で表示（この例では全て円で表示）
	draw_circle(center, square_size * 0.15, move_indicator_color)

func highlight_selected(pos) -> void:
	# マスの選択状態を設定
	highlight_position = pos
	queue_redraw()

func highlight_valid_moves(moves) -> void:
	# 移動可能なマスを設定
	valid_move_positions = moves
	queue_redraw()

func clear_highlights() -> void:
	# ハイライト表示をクリア
	highlight_position = null
	valid_move_positions = []
	queue_redraw()

func _input(event: InputEvent) -> void:
	# マウスクリックの処理
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = to_local(event.global_position)
		var grid_pos = Vector2(int(local_pos.x / square_size), int(local_pos.y / square_size))
		
		# ボード内のクリックかチェック
		if grid_pos.x >= 0 and grid_pos.x < board_size and grid_pos.y >= 0 and grid_pos.y < board_size:
			# テスト用：クリックしたマスをハイライト表示
			if highlight_position == grid_pos:
				clear_highlights()  # 同じマスをクリックしたらクリア
			else:
				highlight_selected(grid_pos)
				
				# テスト用：ランダムな移動可能マスを表示
				var test_moves = []
				for i in range(3):  # 3つのランダムなマスを表示
					var x = randi() % board_size
					var y = randi() % board_size
					test_moves.append(Vector2(x, y))
				highlight_valid_moves(test_moves)