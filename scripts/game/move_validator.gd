extends Node

# 移動の有効性を検証するクラス

var game_state

func _ready():
    game_state = get_parent().get_node("GameState")

func is_valid_move(piece, to_pos):
    # ゲーム状態から有効な移動を取得
    var valid_moves = game_state.get_valid_moves(piece)
    
    # 移動先が有効な移動リストに含まれているか確認
    return to_pos in valid_moves

func is_valid_captured_piece_placement(piece_index, to_pos, player):
    # 配置可能かチェック
    if not game_state._is_valid_position(to_pos) or game_state.board[to_pos.x][to_pos.y] != null:
        return false
    
    var captured_pieces = game_state.captured_pieces[player]
    if piece_index < 0 or piece_index >= captured_pieces.size():
        return false
    
    var piece = captured_pieces[piece_index]
    
    # ポーンの配置制限
    if piece.type == Globals.PieceType.PAWN:
        if to_pos.y == 0 or to_pos.y == 7:
            return false
    
    # 配置後にチェックが解消されるか確認
    var king = game_state._find_king(player)
    if king:
        # 一時的に駒を配置
        game_state.board[to_pos.x][to_pos.y] = piece
        var is_in_check = game_state._is_square_attacked(king.board_position, player)
        game_state.board[to_pos.x][to_pos.y] = null  # 元に戻す
        
        if is_in_check:
            return false  # チェック状態が解消されない
    
    return true