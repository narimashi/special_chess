extends Sprite

# 駒のビジュアル表現とインタラクション

var type
var player
var board_position
var has_moved = false
var is_dragging = false
var drag_offset = Vector2()

func initialize(piece_type, piece_player, pos):
    type = piece_type
    player = piece_player
    board_position = pos
    
    position = _board_to_screen_position(board_position)
    texture = _get_piece_texture()

func _board_to_screen_position(board_pos):
    return Vector2(
        board_pos.x * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE / 2,
        board_pos.y * Globals.SQUARE_SIZE + Globals.SQUARE_SIZE / 2
    )

func _get_piece_texture():
    var piece_name = ""
    match type:
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

func move_to(new_pos):
    board_position = new_pos
    position = _board_to_screen_position(board_position)

func start_drag(mouse_pos):
    is_dragging = true
    drag_offset = position - mouse_pos
    z_index = 1  # ドラッグ中は他の駒より前面に表示

func continue_drag(mouse_pos):
    if is_dragging:
        position = mouse_pos + drag_offset

func end_drag():
    is_dragging = false
    z_index = 0  # 通常の表示順に戻す
    position = _board_to_screen_position(board_position)

func update_type(new_type):
    # 駒の種類が変わった場合（昇格など）
    type = new_type
    texture = _get_piece_texture()

func _input(event):
    if is_dragging and event is InputEventMouseMotion:
        continue_drag(event.position)
    
    if is_dragging and event is InputEventMouseButton and event.button_index == BUTTON_LEFT and not event.pressed:
        end_drag()
        # 親に通知
        get_parent().on_piece_dropped(self, event.position)