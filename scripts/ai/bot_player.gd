extends Node

# AIプレイヤー（ボット）

signal move_complete

var game_state
var player_color: int
var difficulty: int
var thinking: bool = false

func _ready() -> void:
	# 2秒のタイムラグを設定（ユーザー体験向上のため）
	$ThinkTimer.wait_time = 2.0
	$ThinkTimer.one_shot = true
	$ThinkTimer.timeout.connect(_on_think_timer_timeout)

func initialize(state_ref, bot_color: int, bot_difficulty: int) -> void:
	game_state = state_ref
	player_color = bot_color
	difficulty = bot_difficulty

func make_move() -> void:
	if thinking:
		return
	
	thinking = true
	$ThinkTimer.start()

func _on_think_timer_timeout() -> void:
	# 難易度に応じた動きを実行
	var success = false
	
	match difficulty:
		Globals.Difficulty.EASY:
			success = _make_random_move()
		Globals.Difficulty.MEDIUM:
			success = _make_medium_move()
		Globals.Difficulty.HARD:
			success = _make_hard_move()
	
	thinking = false
	
	if not success:
		# 有効な手がない場合、ゲーム終了条件をチェック
		if game_state.is_checkmate(player_color):
			get_parent().get_node("GameState").game_over.emit(Globals.Player.WHITE if player_color == Globals.Player.BLACK else Globals.Player.BLACK)
		elif game_state.is_stalemate(player_color):
			get_parent().get_node("GameState").game_over.emit(null)  # 引き分け
	else:
		move_complete.emit()

func _make_random_move() -> bool:
	# ボットの駒をランダムに選択し、有効な移動先をランダムに選ぶ
	var pieces = game_state.get_player_pieces(player_color)
	
	# 持ち駒があり、ランダムで持ち駒を使う場合
	var captured_pieces = game_state.captured_pieces[player_color]
	if not captured_pieces.is_empty() and randf() < 0.3:
		return _place_random_captured_piece()
	
	# 駒がなければ負け
	if pieces.is_empty():
		return false
	
	# ランダムな順序で駒をシャッフル
	pieces.shuffle()
	
	# 有効な移動がある駒を探す
	for piece in pieces:
		var valid_moves = game_state.get_valid_moves(piece)
		
		if not valid_moves.is_empty():
			# ランダムな移動先を選択
			valid_moves.shuffle()
			var target_pos = valid_moves[0]
			
			# 昇格が必要かチェック
			var promotion_type = null
			if piece.type == Globals.PieceType.PAWN:
				if (player_color == Globals.Player.WHITE and target_pos.y == 0) or (player_color == Globals.Player.BLACK and target_pos.y == 7):
					# ランダムな昇格先を選択
					var promotion_types = [Globals.PieceType.QUEEN, Globals.PieceType.ROOK, Globals.PieceType.BISHOP, Globals.PieceType.KNIGHT]
					promotion_type = promotion_types[randi() % promotion_types.size()]
			
			# 移動を実行
			return game_state.move_piece(piece, target_pos, promotion_type)
	
	return false

func _make_medium_move() -> bool:
	# より賢い行動（チェック、駒取りを優先）
	var pieces = game_state.get_player_pieces(player_color)
	var opponent = Globals.Player.BLACK if player_color == Globals.Player.WHITE else Globals.Player.WHITE
	
	# 持ち駒がある場合、30%の確率で使用
	var captured_pieces = game_state.captured_pieces[player_color]
	if not captured_pieces.is_empty() and randf() < 0.3:
		return _place_strategic_captured_piece()
	
	# 駒がなければ負け
	if pieces.is_empty():
		return false
	
	# チェックを狙う手を探す
	var check_moves = []
	
	# 駒を取る手を探す
	var capture_moves = []
	
	# 安全な手を探す
	var safe_moves = []
	
	for piece in pieces:
		var valid_moves = game_state.get_valid_moves(piece)
		
		for move in valid_moves:
			# チェックになる手
			if _move_causes_check(piece, move, opponent):
				check_moves.append([piece, move])
			
			# 駒を取る手
			elif game_state.get_piece_at(move) != null:
				capture_moves.append([piece, move])
			
			# 安全な手（相手に取られない）
			elif not _is_threatened_after_move(piece, move):
				safe_moves.append([piece, move])
			
			# その他の手
			else:
				safe_moves.append([piece, move])
	
	# 優先順位: チェック > 駒取り > 安全な手
	var selected_move = null
	
	if not check_moves.is_empty():
		check_moves.shuffle()
		selected_move = check_moves[0]
	elif not capture_moves.is_empty():
		# 価値の高い駒を優先して取る
		capture_moves.sort_custom(_sort_by_capture_value)
		selected_move = capture_moves[0]
	elif not safe_moves.is_empty():
		safe_moves.shuffle()
		selected_move = safe_moves[0]
	else:
		return _make_random_move()  # 有効な手がない場合はランダム
	
	var target_piece = selected_move[0]
	var target_pos = selected_move[1]
	
	# 昇格が必要かチェック
	var promotion_type = null
	if target_piece.type == Globals.PieceType.PAWN:
		if (player_color == Globals.Player.WHITE and target_pos.y == 0) or (player_color == Globals.Player.BLACK and target_pos.y == 7):
			promotion_type = Globals.PieceType.QUEEN  # 常にクイーンに昇格
	
	# 移動を実行
	return game_state.move_piece(target_piece, target_pos, promotion_type)

func _make_hard_move() -> bool:
	# 最も強い動き（将来的にミニマックスアルゴリズムなどで実装）
	# 現時点ではミディアムと同じ
	return _make_medium_move()

func _place_random_captured_piece() -> bool:
	var captured_pieces = game_state.captured_pieces[player_color]
	if captured_pieces.is_empty():
		return false
	
	# ランダムな持ち駒を選択
	var piece_index = randi() % captured_pieces.size()
	var piece = captured_pieces[piece_index]
	
	# 配置可能なマスを探す
	var valid_positions = []
	
	for x in range(Globals.BOARD_SIZE):
		for y in range(Globals.BOARD_SIZE):
			var pos = Vector2(x, y)
			
			# マスが空いているか確認
			if game_state.get_piece_at(pos) == null:
				# ポーンの場合は1段目と8段目には置けない
				if piece.type == Globals.PieceType.PAWN:
					if y != 0 and y != 7:
						valid_positions.append(pos)
				else:
					valid_positions.append(pos)
	
	if valid_positions.is_empty():
		return false
	
	# ランダムな位置を選択
	valid_positions.shuffle()
	var target_pos = valid_positions[0]
	
	# 持ち駒を配置
	return game_state.place_captured_piece(piece_index, target_pos)

func _place_strategic_captured_piece() -> bool:
	var captured_pieces = game_state.captured_pieces[player_color]
	if captured_pieces.is_empty():
		return false
	
	var opponent = Globals.Player.BLACK if player_color == Globals.Player.WHITE else Globals.Player.WHITE
	
	# 戦略的な配置を探す
	var check_placements = []  # チェックになる配置
	var fork_placements = []   # フォークになる配置
	var safe_placements = []   # 安全な配置
	
	for piece_index in range(captured_pieces.size()):
		var piece = captured_pieces[piece_index]
		
		for x in range(Globals.BOARD_SIZE):
			for y in range(Globals.BOARD_SIZE):
				var pos = Vector2(x, y)
				
				# マスが空いているか確認
				if game_state.get_piece_at(pos) != null:
					continue
				
				# ポーンの場合は1段目と8段目には置けない
				if piece.type == Globals.PieceType.PAWN and (y == 0 or y == 7):
					continue
				
				# チェックになる配置
				if _placement_causes_check(piece, pos, opponent):
					check_placements.append([piece_index, pos])
				
				# フォークになる配置
				elif _placement_causes_fork(piece, pos):
					fork_placements.append([piece_index, pos])
				
				# 安全な配置（相手に取られない）
				elif not _is_threatened_position(pos):
					safe_placements.append([piece_index, pos])
	
	# 優先順位: チェック > フォーク > 安全
	var selected_placement = null
	
	if not check_placements.is_empty():
		check_placements.shuffle()
		selected_placement = check_placements[0]
	elif not fork_placements.is_empty():
		fork_placements.shuffle()
		selected_placement = fork_placements[0]
	elif not safe_placements.is_empty():
		safe_placements.shuffle()
		selected_placement = safe_placements[0]
	else:
		return _place_random_captured_piece()  # 有効な配置がない場合はランダム
	
	var piece_index = selected_placement[0]
	var target_pos = selected_placement[1]
	
	# 持ち駒を配置
	return game_state.place_captured_piece(piece_index, target_pos)

func _move_causes_check(piece, target_pos: Vector2, opponent: int) -> bool:
	var original_pos = piece.board_position
	var original_target_piece = game_state.get_piece_at(target_pos)
	
	# 一時的に移動
	game_state.board[original_pos.x][original_pos.y] = null
	piece.board_position = target_pos
	game_state.board[target_pos.x][target_pos.y] = piece
	
	# チェック状態をチェック
	var is_check = game_state.is_in_check(opponent)
	
	# 元に戻す
	game_state.board[target_pos.x][target_pos.y] = original_target_piece
	piece.board_position = original_pos
	game_state.board[original_pos.x][original_pos.y] = piece
	
	return is_check

func _is_threatened_after_move(piece, target_pos: Vector2) -> bool:
	var original_pos = piece.board_position
	var original_target_piece = game_state.get_piece_at(target_pos)
	
	# 一時的に移動
	game_state.board[original_pos.x][original_pos.y] = null
	piece.board_position = target_pos
	game_state.board[target_pos.x][target_pos.y] = piece
	
	# 移動後に脅かされているかチェック
	var is_threatened = _is_threatened_position(target_pos)
	
	# 元に戻す
	game_state.board[target_pos.x][target_pos.y] = original_target_piece
	piece.board_position = original_pos
	game_state.board[original_pos.x][original_pos.y] = piece
	
	return is_threatened

func _is_threatened_position(pos: Vector2) -> bool:
	var opponent = Globals.Player.BLACK if player_color == Globals.Player.WHITE else Globals.Player.WHITE
	
	# その位置が相手の駒に攻撃されるかチェック
	return game_state._is_square_attacked(pos, player_color)

func _placement_causes_check(piece, pos: Vector2, opponent: int) -> bool:
	# 一時的に配置
	game_state.board[pos.x][pos.y] = piece
	
	# チェック状態をチェック
	var is_check = game_state.is_in_check(opponent)
	
	# 元に戻す
	game_state.board[pos.x][pos.y] = null
	
	return is_check

func _placement_causes_fork(piece, pos: Vector2) -> bool:
	var opponent = Globals.Player.BLACK if player_color == Globals.Player.WHITE else Globals.Player.WHITE
	var threatened_pieces = 0
	
	# 一時的に配置
	game_state.board[pos.x][pos.y] = piece
	
	# この駒から攻撃できる相手の駒の数をカウント
	for x in range(Globals.BOARD_SIZE):
		for y in range(Globals.BOARD_SIZE):
			var target = game_state.board[x][y]
			if target and target.player == opponent:
				if _can_attack_from_to(piece, pos, Vector2(x, y)):
					threatened_pieces += 1
	
	# 元に戻す
	game_state.board[pos.x][pos.y] = null
	
	# 2つ以上の駒を脅かしている場合はフォーク
	return threatened_pieces >= 2

func _can_attack_from_to(piece, from_pos: Vector2, to_pos: Vector2) -> bool:
	# 駒の種類に応じて攻撃可能かチェック
	match piece.type:
		Globals.PieceType.PAWN:
			# ポーンは斜め前方にのみ攻撃可能
			var direction = -1 if player_color == Globals.Player.WHITE else 1
			var dx = to_pos.x - from_pos.x
			var dy = to_pos.y - from_pos.y
			return abs(dx) == 1 and dy == direction
		
		Globals.PieceType.KNIGHT:
			# ナイトは L字型に移動・攻撃
			var dx = abs(to_pos.x - from_pos.x)
			var dy = abs(to_pos.y - from_pos.y)
			return (dx == 1 and dy == 2) or (dx == 2 and dy == 1)
		
		Globals.PieceType.BISHOP:
			# ビショップは斜めに攻撃
			var dx = abs(to_pos.x - from_pos.x)
			var dy = abs(to_pos.y - from_pos.y)
			if dx != dy:
				return false
			
			# 間に駒がないか確認
			var dir_x = 1 if to_pos.x > from_pos.x else -1
			var dir_y = 1 if to_pos.y > from_pos.y else -1
			var current = Vector2(from_pos.x + dir_x, from_pos.y + dir_y)
			
			while current != to_pos:
				if game_state.board[current.x][current.y] != null:
					return false
				current.x += dir_x
				current.y += dir_y
			
			return true
		
		Globals.PieceType.ROOK:
			# ルークは縦横に攻撃
			if to_pos.x != from_pos.x and to_pos.y != from_pos.y:
				return false
			
			# 間に駒がないか確認
			var dir_x = 0
			var dir_y = 0
			
			if to_pos.x > from_pos.x:
				dir_x = 1
			elif to_pos.x < from_pos.x:
				dir_x = -1
			elif to_pos.y > from_pos.y:
				dir_y = 1
			else:
				dir_y = -1
			
			var current = Vector2(from_pos.x + dir_x, from_pos.y + dir_y)
			
			while current != to_pos:
				if game_state.board[current.x][current.y] != null:
					return false
				current.x += dir_x
				current.y += dir_y
			
			return true
		
		Globals.PieceType.QUEEN:
			# クイーンは縦横斜めに攻撃（ルーク+ビショップ）
			var dx = abs(to_pos.x - from_pos.x)
			var dy = abs(to_pos.y - from_pos.y)
			
			if dx != 0 and dy != 0 and dx != dy:
				return false
			
			# 間に駒がないか確認
			var dir_x = 0
			var dir_y = 0
			
			if to_pos.x > from_pos.x:
				dir_x = 1
			elif to_pos.x < from_pos.x:
				dir_x = -1
			
			if to_pos.y > from_pos.y:
				dir_y = 1
			elif to_pos.y < from_pos.y:
				dir_y = -1
			
			var current = Vector2(from_pos.x + dir_x, from_pos.y + dir_y)
			
			while current != to_pos:
				if game_state.board[current.x][current.y] != null:
					return false
				current.x += dir_x
				current.y += dir_y
			
			return true
		
		Globals.PieceType.KING:
			# キングは1マス移動
			var dx = abs(to_pos.x - from_pos.x)
			var dy = abs(to_pos.y - from_pos.y)
			return dx <= 1 and dy <= 1
	
	return false

func _sort_by_capture_value(a, b) -> bool:
	# 駒の価値
	var piece_values = {
		Globals.PieceType.PAWN: 1,
		Globals.PieceType.KNIGHT: 3,
		Globals.PieceType.BISHOP: 3,
		Globals.PieceType.ROOK: 5,
		Globals.PieceType.QUEEN: 9,
		Globals.PieceType.KING: 100
	}
	
	var target_a = game_state.get_piece_at(a[1])
	var target_b = game_state.get_piece_at(b[1])
	
	if target_a == null:
		return false
	if target_b == null:
		return true
	
	# 価値の高い駒を優先
	return piece_values[target_a.type] > piece_values[target_b.type]