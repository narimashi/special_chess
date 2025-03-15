# 音声ファイルのプリロード
extends Node2D
func _preload_audio_files() -> void:
	if not Globals.sound_enabled:
		return
		
	var sound_paths = {
		"GameStart": "res://assets/sounds/game_start.mp3",
		"Move": "res://assets/sounds/move.mp3",
		"Capture": "res://assets/sounds/capture.mp3",
		"Check": "res://assets/sounds/check.mp3",
		"Victory": "res://assets/sounds/victory.mp3",
		"Defeat": "res://assets/sounds/defeat.mp3",
		"Tactic": "res://assets/sounds/tactic.mp3"
	}
	
	for sound_name in sound_paths:
		var node_path = "Sounds/" + sound_name
		if has_node(node_path):
			var audio_path = sound_paths[sound_name]
			var audio_player = get_node(node_path)
			
			# MP3ファイルが存在すればロード
			if ResourceLoader.exists(audio_path):
				audio_player.stream = load(audio_path)
			else:
				# 音声ファイルがない場合は無音のストリームを作成
				var stream = AudioStreamMP3.new()
				audio_player.stream = stream

# ゲーム開始
func _start_game() -> void:
	# ゲーム開始音の再生
	if Globals.sound_enabled and has_node("Sounds/GameStart") and $Sounds/GameStart.stream != null:
		$Sounds/GameStart.play()



# ゲーム画面の管理

var game_state
var bot_player
var current_player: int = Globals.Player.WHITE
var selected_piece = null
var valid_moves: Array = []
var is_game_over: bool = false
var selected_captured_piece = null

# スクリーンショット機能のためのカウンタ
var screenshot_counter: int = 0

func _ready() -> void:
	# ゲーム状態の初期化
	game_state = $GameState
	game_state.game_over.connect(_on_game_over)
	game_state.check.connect(_on_check)
	game_state.tactic_detected.connect(_on_tactic_detected)
	
	# ボットプレイヤーの初期化
	bot_player = $BotPlayer
	bot_player.initialize(game_state, Globals.Player.BLACK, Globals.current_difficulty)
	bot_player.move_complete.connect(_switch_player)
	
	# UIの初期化
	_update_ui()
	
	# MP3音声ファイルのプリロード
	_preload_audio_files()
	
	# ゲーム開始
	_start_game()

func _process(_delta: float) -> void:
	# ボットの番かチェック
	if current_player == Globals.Player.BLACK and !is_game_over:
		bot_player.make_move()

func _input(event: InputEvent) -> void:
	if is_game_over:
		return
		
	if current_player != Globals.Player.WHITE:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos = get_global_mouse_position()
		_handle_click(click_pos)
	
	# デバッグ機能: F12でスクリーンショット
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		_take_screenshot()

func _handle_click(click_pos: Vector2) -> void:
	# 盤上の位置を計算
	var board_pos = _get_board_position(click_pos)
	
	# 持ち駒エリアのクリック判定
	if _is_captured_area_click(click_pos):
		_handle_captured_area_click(click_pos)
		return
		
	# 盤外のクリックは無視
	if !_is_valid_board_position(board_pos):
		return
	
	if selected_captured_piece != null:
		# 持ち駒を選択中の場合、盤上に配置を試みる
		_try_place_captured_piece(board_pos)
	elif selected_piece != null:
		# 駒を選択中の場合
		if board_pos in valid_moves:
			# 有効な移動先なら移動
			_move_piece(selected_piece, board_pos)
		else:
			# 別の駒を選択
			_select_piece_at(board_pos)
	else:
		# 新しく駒を選択
		_select_piece_at(board_pos)

func _select_piece_at(board_pos: Vector2) -> void:
	var piece = game_state.get_piece_at(board_pos)
	
	if piece and piece.player == current_player:
		selected_piece = piece
		valid_moves = game_state.get_valid_moves(piece)
		$Board.highlight_selected(board_pos)
		$Board.highlight_valid_moves(valid_moves)
	else:
		selected_piece = null
		valid_moves = []
		$Board.clear_highlights()

func _try_place_captured_piece(board_pos: Vector2) -> void:
	var success = game_state.place_captured_piece(selected_captured_piece, board_pos)
	
	if success:
		if Globals.sound_enabled:
			$Sounds/Move.play()
			
		selected_captured_piece = null
		$CapturedArea.clear_selection()
		_switch_player()
	else:
		# 配置失敗
		selected_captured_piece = null
		$CapturedArea.clear_selection()

func _move_piece(piece, to_pos: Vector2) -> void:
	var from_pos = piece.board_position
	var captured = game_state.get_piece_at(to_pos)
	var promotion_needed = _is_promotion_needed(piece, to_pos)
	
	if promotion_needed:
		# 成り駒の選択ダイアログを表示
		$PromotionDialog.show_for_piece(piece, to_pos)
		await $PromotionDialog.promotion_selected
	
	var success = game_state.move_piece(piece, to_pos)
	
	if success:
		if captured:
			_play_sound("Capture")
		else:
			_play_sound("Move")
				
		selected_piece = null
		valid_moves = []
		$Board.clear_highlights()
		
		# 戦術の検出
		var tactics = $TacticDetector.detect_tactics(piece, from_pos, to_pos)
		for tactic in tactics:
			_on_tactic_detected(tactic)
		
		_switch_player()

func _switch_player() -> void:
	current_player = Globals.Player.BLACK if current_player == Globals.Player.WHITE else Globals.Player.WHITE
	_update_ui()
	
	# チェック状態の確認
	if game_state.is_in_check(current_player):
		_on_check()
		
		# チェックメイト・ステイルメイトの確認
		if game_state.is_checkmate(current_player):
			_on_game_over(Globals.Player.WHITE if current_player == Globals.Player.BLACK else Globals.Player.BLACK)
	elif game_state.is_stalemate(current_player):
		_on_game_over(null)  # 引き分け

func _update_ui() -> void:
	# ターン表示の更新
	$UI/TurnLabel.text = "Turn: " + Globals.get_player_name(current_player)
	
	# 持ち駒表示の更新
	$CapturedArea.update_display(game_state.get_captured_pieces())

func _is_promotion_needed(piece, to_pos: Vector2) -> bool:
	return piece.type == Globals.PieceType.PAWN and (
		(piece.player == Globals.Player.WHITE and to_pos.y == 0) or
		(piece.player == Globals.Player.BLACK and to_pos.y == 7)
	)

func _get_board_position(screen_pos: Vector2) -> Vector2:
	var local_pos = $Board.to_local(screen_pos)
	var col = int(local_pos.x / Globals.SQUARE_SIZE)
	var row = int(local_pos.y / Globals.SQUARE_SIZE)
	return Vector2(col, row)

func _is_valid_board_position(pos: Vector2) -> bool:
	return pos.x >= 0 and pos.x < Globals.BOARD_SIZE and pos.y >= 0 and pos.y < Globals.BOARD_SIZE

func _is_captured_area_click(screen_pos: Vector2) -> bool:
	return $CapturedArea.get_rect().has_point($CapturedArea.to_local(screen_pos))

func _handle_captured_area_click(screen_pos: Vector2) -> void:
	var index = $CapturedArea.get_piece_index_at(screen_pos)
	
	if index >= 0:
		selected_piece = null
		valid_moves = []
		$Board.clear_highlights()
		
		selected_captured_piece = index
		$CapturedArea.highlight_piece(current_player, index)
	else:
		selected_captured_piece = null
		$CapturedArea.clear_selection()

# 効果音再生
func _play_sound(sound_name: String) -> void:
	if not Globals.sound_enabled:
		return
		
	var node_path = "Sounds/" + sound_name
	if has_node(node_path):
		var audio_player = get_node(node_path)
		if audio_player.stream != null:
			audio_player.play()

func _on_check() -> void:
	_play_sound("Check")
	$CutInManager.play_cutin("check")

func _on_tactic_detected(tactic: String) -> void:
	_play_sound("Tactic")
	$CutInManager.play_cutin(tactic)

func _on_game_over(winner) -> void:
	is_game_over = true
	
	if winner == null:
		# 引き分け
		$GameOverDialog.show_draw()
	else:
		# 勝敗あり
		$GameOverDialog.show_winner(winner)
		
		if winner == Globals.Player.WHITE:
			_play_sound("Victory")
		else:
			_play_sound("Defeat")

func _on_resign_button_pressed() -> void:
	if !is_game_over:
		# 確認ダイアログを表示
		$ResignConfirmDialog.popup_centered()

func _on_resign_confirmed() -> void:
	if !is_game_over:
		# 現在のプレイヤーの投了
		var winner = Globals.Player.BLACK if current_player == Globals.Player.WHITE else Globals.Player.WHITE
		_on_game_over(winner)

func _on_main_menu_button_pressed() -> void:
	# メインメニューへ戻る
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _take_screenshot() -> void:
	# スクリーンショット撮影（デバッグ機能）
	var image = get_viewport().get_texture().get_image()
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "user://screenshot_%02d%02d%02d_%02d%02d%02d_%03d.png" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second,
		screenshot_counter
	]
	screenshot_counter += 1
	image.save_png(filename)
	print("Screenshot saved to: " + filename)
