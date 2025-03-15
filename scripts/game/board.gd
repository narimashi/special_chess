extends Node2D

# チェスボードの表示を管理するクラス

# ボードのテーマカラー
export var light_square_color = Color(0.9, 0.9, 0.8)
export var dark_square_color = Color(0.5, 0.4, 0.3)
export var highlight_color = Color(0.3, 0.7, 0.3, 0.5)
export var move_indicator_color = Color(0.2, 0.6, 0.9, 0.5)

var highlight_position = null
var valid_move_positions = []
var game_state = null

func _ready():
    # ゲーム状態参照の取得
    game_state = get_parent().get_node("GameState")
    game_state.connect("board_updated", self, "_on_board_updated")
    
    # 初期ボード状態の描画
    update()

func _draw():
    # ボードの描画
    _draw_board()
    
    # ハイライト表示
    if highlight_position != null:
        _draw_highlight(highlight_position)
    
    # 有効移動先の表示
    for pos in valid_move_positions:
        _draw_move_indicator(pos)
    
    # 駒の描画（ゲーム状態から）
    if game_state:
        _draw_pieces()

func _draw_board():
    # 8x8のチェスボードを描画
    for x in range(Globals.BOARD_SIZE):
        for y in range(Globals.BOARD_SIZE):
            var color = light_square_color if (x + y) % 2 == 0 else dark_square_color
            var rect = Rect2(x * Globals.SQUARE_SIZE, y * Globals.SQUARE_SIZE, 
                           Globals.SQUARE_SIZE, Globals.SQUARE_SIZE)
            draw_rect(rect, color)
    
    # ボード枠線
    var border_rect = Rect2(0, 0, Globals.BOARD_SIZE * Globals.SQUARE_SIZE, 
                          Globals.BOARD_SIZE * Globals.SQUARE_SIZE)
    draw_rect(border_rect, Color.black, false, 2.0)
    
    # 座標ラベル（a-h, 1-8）
    _draw_coordinate_labels()

func _draw_coordinate_labels():
    var font = get_font("font", "Label")
    var label_color = Color(0.2, 0.2, 0.2)
    
    # 横座標（a-h）
    for i in range(Globals.BOARD_SIZE):
        var label = char(97 + i)  # aから始まるアルファベット
        var pos = Vector2(i * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE * 0.5, 
                         Globals.BOARD_SIZE * Globals.SQUARE_SIZE + 15)
        draw_string(font, pos, label, label_color)
    
    # 縦座標（1-8）、上から8,7,6...
    for i in range(Globals.BOARD_SIZE):
        var label = str(Globals.BOARD_SIZE - i)
        var pos = Vector2(-15, i * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE * 0.5)
        draw_string(font, pos, label, label_color)

func _draw_pieces():
    # ゲーム状態から駒情報を取得して描画
    var pieces = game_state.get_all_pieces()
    
    for piece in pieces:
        var texture = _get_piece_texture(piece.type, piece.player)
        var pos = Vector2(
            piece.board_position.x * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE / 2,
            piece.board_position.y * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE / 2
        )
        draw_texture_centered(texture, pos)

func _draw_highlight(pos):
    # 選択中の駒のハイライト
    var rect = Rect2(pos.x * Globals.SQUARE_SIZE, pos.y * Globals.SQUARE_SIZE,
                   Globals.SQUARE_SIZE, Globals.SQUARE_SIZE)
    draw_rect(rect, highlight_color)

func _draw_move_indicator(pos):
    # 移動可能位置の表示
    var center = Vector2(
        pos.x * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE / 2,
        pos.y * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE / 2
    )
    
    # 駒があるマスは枠線、空きマスは円で表示
    if game_state.get_piece_at(pos):
        var rect = Rect2(pos.x * Globals.SQUARE_SIZE, pos.y * Globals.SQUARE_SIZE,
                       Globals.SQUARE_SIZE, Globals.SQUARE_SIZE)
        draw_rect(rect, move_indicator_color, false, 3.0)
    else:
        draw_circle(center, Globals.SQUARE_SIZE * 0.15, move_indicator_color)

func draw_texture_centered(texture, position):
    # テクスチャを中央揃えで描画
    var size = texture.get_size()
    var dest_rect = Rect2(position.x - size.x / 2, position.y - size.y / 2, size.x, size.y)
    draw_texture_rect(texture, dest_rect, false)

func _get_piece_texture(piece_type, player):
    # 駒の種類とプレイヤーに応じたテクスチャを返す
    var piece_name = ""
    match piece_type:
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
    
    var color = "white" if player == Globals.Player.WHITE else "black"
    return load("res://assets/pieces/" + color + "_" + piece_name + ".png")

func highlight_selected(pos):
    highlight_position = pos
    update()

func highlight_valid_moves(moves):
    valid_move_positions = moves
    update()

func clear_highlights():
    highlight_position = null
    valid_move_positions = []
    update()

func _on_board_updated():
    # ボード状態が変更されたら再描画
    update()