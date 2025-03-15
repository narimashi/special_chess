extends Node

# ゲーム状態を管理するクラス

# 信号
signal board_updated
signal check
signal game_over(winner)
signal tactic_detected(tactic_name)

# ボード表現 (8x8の2次元配列)
var board = []

# 持ち駒
var captured_pieces = {
    Globals.Player.WHITE: [],
    Globals.Player.BLACK: []
}

# 特殊ルール用の状態
var castling_rights = {
    Globals.Player.WHITE: {
        "kingside": true,
        "queenside": true
    },
    Globals.Player.BLACK: {
        "kingside": true,
        "queenside": true
    }
}

# アンパッサン可能な位置
var en_passant_target = null

# ゲーム履歴
var move_history = []

class ChessPiece:
    var type
    var player
    var board_position
    var has_moved = false
    
    func _init(piece_type, piece_player, pos):
        type = piece_type
        player = piece_player
        board_position = pos
    
    func to_string():
        var type_str = Globals.piece_to_char[type]
        if player == Globals.Player.BLACK:
            type_str = type_str.to_lower()
        return type_str

func _ready():
    # ボードの初期化
    _initialize_board()
    _setup_pieces()

func _initialize_board():
    # 8x8の空のボードを作成
    board = []
    for x in range(Globals.BOARD_SIZE):
        var row = []
        for y in range(Globals.BOARD_SIZE):
            row.append(null)  # 空のマス
        board.append(row)

func _setup_pieces():
    # 初期配置
    # ポーン
    for x in range(Globals.BOARD_SIZE):
        _add_piece(Globals.PieceType.PAWN, Globals.Player.WHITE, Vector2(x, 6))
        _add_piece(Globals.PieceType.PAWN, Globals.Player.BLACK, Vector2(x, 1))
    
    # ルーク
    _add_piece(Globals.PieceType.ROOK, Globals.Player.WHITE, Vector2(0, 7))
    _add_piece(Globals.PieceType.ROOK, Globals.Player.WHITE, Vector2(7, 7))
    _add_piece(Globals.PieceType.ROOK, Globals.Player.BLACK, Vector2(0, 0))
    _add_piece(Globals.PieceType.ROOK, Globals.Player.BLACK, Vector2(7, 0))
    
    # ナイト
    _add_piece(Globals.PieceType.KNIGHT, Globals.Player.WHITE, Vector2(1, 7))
    _add_piece(Globals.PieceType.KNIGHT, Globals.Player.WHITE, Vector2(6, 7))
    _add_piece(Globals.PieceType.KNIGHT, Globals.Player.BLACK, Vector2(1, 0))
    _add_piece(Globals.PieceType.KNIGHT, Globals.Player.BLACK, Vector2(6, 0))
    
    # ビショップ
    _add_piece(Globals.PieceType.BISHOP, Globals.Player.WHITE, Vector2(2, 7))
    _add_piece(Globals.PieceType.BISHOP, Globals.Player.WHITE, Vector2(5, 7))
    _add_piece(Globals.PieceType.BISHOP, Globals.Player.BLACK, Vector2(2, 0))
    _add_piece(Globals.PieceType.BISHOP, Globals.Player.BLACK, Vector2(5, 0))
    
    # クイーン
    _add_piece(Globals.PieceType.QUEEN, Globals.Player.WHITE, Vector2(3, 7))
    _add_piece(Globals.PieceType.QUEEN, Globals.Player.BLACK, Vector2(3, 0))
    
    # キング
    _add_piece(Globals.PieceType.KING, Globals.Player.WHITE, Vector2(4, 7))
    _add_piece(Globals.PieceType.KING, Globals.Player.BLACK, Vector2(4, 0))
    
    # 盤面更新を通知
    emit_signal("board_updated")

func _add_piece(type, player, pos):
    var piece = ChessPiece.new(type, player, pos)
    board[pos.x][pos.y] = piece
    return piece

func get_piece_at(pos):
    if _is_valid_position(pos):
        return board[pos.x][pos.y]
    return null

func get_all_pieces():
    var pieces = []
    for x in range(Globals.BOARD_SIZE):
        for y in range(Globals.BOARD_SIZE):
            if board[x][y] != null:
                pieces.append(board[x][y])
    return pieces

func get_player_pieces(player):
    var pieces = []
    for piece in get_all_pieces():
        if piece.player == Globals.Player.WHITE:
            white_count += 1
        else:
            black_count += 1
    
    # 白と黒の数が同じなら白番、それ以外は黒番
    return Globals.Player.WHITE if white_count == black_count else Globals.Player.BLACK

func get_board_string():
    # デバッグ用のボード表示
    var result = ""
    for y in range(Globals.BOARD_SIZE):
        var row = ""
        for x in range(Globals.BOARD_SIZE):
            var piece = board[x][y]
            if piece:
                row += piece.to_string() + " "
            else:
                row += ". "
        result += row + "\n"
    return result():
        if piece.player == player:
            pieces.append(piece)
    return pieces

func get_captured_pieces():
    return captured_pieces

func move_piece(piece, to_pos, promotion_type=null):
    var from_pos = piece.board_position
    var captured = get_piece_at(to_pos)
    var is_castling = _is_castling_move(piece, to_pos)
    var is_en_passant = _is_en_passant_move(piece, to_pos)
    
    # 移動前の状態を記録
    var move_data = {
        "piece": piece,
        "from": from_pos,
        "to": to_pos,
        "captured": captured,
        "is_castling": is_castling,
        "is_en_passant": is_en_passant,
        "castling_rights": castling_rights.duplicate(true),
        "en_passant_target": en_passant_target
    }
    
    # 駒取り処理
    if captured:
        # 持ち駒に追加
        captured_pieces[piece.player].append(captured)
        board[to_pos.x][to_pos.y] = null
    
    # 特殊な動き：アンパッサン
    if is_en_passant:
        var captured_pawn = board[to_pos.x][from_pos.y]
        move_data["en_passant_captured"] = captured_pawn
        captured_pieces[piece.player].append(captured_pawn)
        board[to_pos.x][from_pos.y] = null
    
    # 特殊な動き：キャスリング
    if is_castling:
        var rook_from_x = 0 if to_pos.x < from_pos.x else 7
        var rook_to_x = 3 if to_pos.x < from_pos.x else 5
        var rook = board[rook_from_x][to_pos.y]
        
        move_data["castling_rook"] = rook
        move_data["castling_rook_from"] = Vector2(rook_from_x, to_pos.y)
        move_data["castling_rook_to"] = Vector2(rook_to_x, to_pos.y)
        
        # ルークの移動
        board[rook_from_x][to_pos.y] = null
        rook.board_position = Vector2(rook_to_x, to_pos.y)
        board[rook_to_x][to_pos.y] = rook
        rook.has_moved = true
    
    # 駒の移動
    board[from_pos.x][from_pos.y] = null
    piece.board_position = to_pos
    
    # 昇格処理
    if promotion_type != null and piece.type == Globals.PieceType.PAWN:
        if (piece.player == Globals.Player.WHITE and to_pos.y == 0) or \
           (piece.player == Globals.Player.BLACK and to_pos.y == 7):
            piece.type = promotion_type
            move_data["promotion"] = promotion_type
    
    board[to_pos.x][to_pos.y] = piece
    piece.has_moved = true
    
    # キャスリング権の更新
    _update_castling_rights(piece)
    
    # アンパッサンターゲットの更新
    en_passant_target = null
    if piece.type == Globals.PieceType.PAWN and abs(from_pos.y - to_pos.y) == 2:
        en_passant_target = Vector2(to_pos.x, (from_pos.y + to_pos.y) / 2)
    
    # 移動履歴に追加
    move_history.append(move_data)
    
    # 盤面更新を通知
    emit_signal("board_updated")
    
    return true

func place_captured_piece(piece_index, pos):
    # 配置可能かチェック
    if not _is_valid_position(pos) or board[pos.x][pos.y] != null:
        return false
    
    var player = _get_current_player()
    if piece_index < 0 or piece_index >= captured_pieces[player].size():
        return false
    
    var piece = captured_pieces[player][piece_index]
    
    # ポーンの配置制限
    if piece.type == Globals.PieceType.PAWN:
        if pos.y == 0 or pos.y == 7:
            return false
    
    # 持ち駒リストから削除
    captured_pieces[player].remove(piece_index)
    
    # 盤面に配置
    piece.board_position = pos
    board[pos.x][pos.y] = piece
    
    # 移動履歴に追加
    var move_data = {
        "piece": piece,
        "from": null,  # 持ち駒からの配置
        "to": pos,
        "is_drop": true
    }
    move_history.append(move_data)
    
    # 盤面更新を通知
    emit_signal("board_updated")
    
    return true

func undo_move():
    if move_history.empty():
        return false
    
    var move = move_history.pop_back()
    
    # 駒の復元
    if move.has("is_drop") and move["is_drop"]:
        # 持ち駒からの配置を元に戻す
        var piece = move["piece"]
        board[move["to"].x][move["to"].y] = null
        captured_pieces[piece.player].append(piece)
    else:
        # 通常の移動を元に戻す
        var piece = move["piece"]
        board[move["to"].x][move["to"].y] = null
        piece.board_position = move["from"]
        board[move["from"].x][move["from"].y] = piece
        
        # 昇格を元に戻す
        if move.has("promotion"):
            piece.type = Globals.PieceType.PAWN
        
        # 駒取りを元に戻す
        if move["captured"]:
            board[move["to"].x][move["to"].y] = move["captured"]
            var index = captured_pieces[piece.player].find(move["captured"])
            if index >= 0:
                captured_pieces[piece.player].remove(index)
        
        # アンパッサンによる取りを元に戻す
        if move["is_en_passant"]:
            var captured_pawn = move["en_passant_captured"]
            board[move["to"].x][move["from"].y] = captured_pawn
            var index = captured_pieces[piece.player].find(captured_pawn)
            if index >= 0:
                captured_pieces[piece.player].remove(index)
        
        # キャスリングを元に戻す
        if move["is_castling"]:
            var rook = move["castling_rook"]
            board[move["castling_rook_to"].x][move["castling_rook_to"].y] = null
            rook.board_position = move["castling_rook_from"]
            board[move["castling_rook_from"].x][move["castling_rook_from"].y] = rook
            rook.has_moved = false
        
        # キャスリング権を復元
        castling_rights = move["castling_rights"].duplicate(true)
        
        # アンパッサンターゲットを復元
        en_passant_target = move["en_passant_target"]
        
        # 駒の移動状態を復元
        piece.has_moved = false if not _has_moved_before(piece, move["from"]) else true
    
    # 盤面更新を通知
    emit_signal("board_updated")
    
    return true

func _has_moved_before(piece, pos):
    # その駒がそれ以前に動いたことがあるか確認
    for i in range(move_history.size() - 1):
        var move = move_history[i]
        if move["piece"] == piece and move["from"] != pos:
            return true
    return false

func get_valid_moves(piece):
    var moves = []
    
    if piece == null:
        return moves
    
    var pos = piece.board_position
    
    match piece.type:
        Globals.PieceType.PAWN:
            # ポーンの移動
            moves = _get_pawn_moves(piece)
        Globals.PieceType.ROOK:
            # ルークの移動
            moves = _get_sliding_moves(piece, [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)])
        Globals.PieceType.KNIGHT:
            # ナイトの移動
            moves = _get_knight_moves(piece)
        Globals.PieceType.BISHOP:
            # ビショップの移動
            moves = _get_sliding_moves(piece, [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)])
        Globals.PieceType.QUEEN:
            # クイーンの移動（ルーク+ビショップ）
            moves = _get_sliding_moves(piece, [
                Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
                Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)
            ])
        Globals.PieceType.KING:
            # キングの移動
            moves = _get_king_moves(piece)
    
    # チェックを避ける動きのみフィルタリング
    moves = _filter_moves_that_prevent_check(piece, moves)
    
    return moves

func _get_pawn_moves(piece):
    var moves = []
    var pos = piece.board_position
    var direction = -1 if piece.player == Globals.Player.WHITE else 1
    var start_rank = 6 if piece.player == Globals.Player.WHITE else 1
    
    # 前方への移動
    var forward = Vector2(pos.x, pos.y + direction)
    if _is_valid_position(forward) and board[forward.x][forward.y] == null:
        moves.append(forward)
        
        # 初期位置からの2マス移動
        if pos.y == start_rank:
            var double_forward = Vector2(pos.x, pos.y + 2 * direction)
            if _is_valid_position(double_forward) and board[double_forward.x][double_forward.y] == null:
                moves.append(double_forward)
    
    # 斜め前方への取り
    for dx in [-1, 1]:
        var capture = Vector2(pos.x + dx, pos.y + direction)
        if _is_valid_position(capture):
            var target = board[capture.x][capture.y]
            if target != null and target.player != piece.player:
                moves.append(capture)
    
    # アンパッサン
    if en_passant_target != null:
        for dx in [-1, 1]:
            var en_passant_pos = Vector2(pos.x + dx, pos.y)
            if _is_valid_position(en_passant_pos) and en_passant_pos == Vector2(en_passant_target.x, pos.y):
                if _is_valid_position(en_passant_target) and en_passant_target.y == pos.y + direction:
                    moves.append(en_passant_target)
    
    return moves

func _get_knight_moves(piece):
    var moves = []
    var pos = piece.board_position
    var offsets = [
        Vector2(1, 2), Vector2(2, 1), Vector2(2, -1), Vector2(1, -2),
        Vector2(-1, -2), Vector2(-2, -1), Vector2(-2, 1), Vector2(-1, 2)
    ]
    
    for offset in offsets:
        var target = Vector2(pos.x + offset.x, pos.y + offset.y)
        if _is_valid_position(target):
            var target_piece = board[target.x][target.y]
            if target_piece == null or target_piece.player != piece.player:
                moves.append(target)
    
    return moves

func _get_sliding_moves(piece, directions):
    var moves = []
    var pos = piece.board_position
    
    for dir in directions:
        var current = Vector2(pos.x + dir.x, pos.y + dir.y)
        while _is_valid_position(current):
            var target_piece = board[current.x][current.y]
            if target_piece == null:
                # 空きマスには移動可能
                moves.append(current)
            else:
                # 相手の駒があれば取れる（その方向はそこまで）
                if target_piece.player != piece.player:
                    moves.append(current)
                break
            current = Vector2(current.x + dir.x, current.y + dir.y)
    
    return moves

func _get_king_moves(piece):
    var moves = []
    var pos = piece.board_position
    
    # 通常の1マス移動
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if dx == 0 and dy == 0:
                continue
            
            var target = Vector2(pos.x + dx, pos.y + dy)
            if _is_valid_position(target):
                var target_piece = board[target.x][target.y]
                if target_piece == null or target_piece.player != piece.player:
                    # 敵の利きがある場所には移動できない
                    if not _is_square_attacked(target, piece.player):
                        moves.append(target)
    
    # キャスリング
    if not piece.has_moved and not is_in_check(piece.player):
        # キングサイドキャスリング
        if castling_rights[piece.player]["kingside"]:
            var rook_pos = Vector2(7, pos.y)
            var rook = get_piece_at(rook_pos)
            if rook and rook.type == Globals.PieceType.ROOK and not rook.has_moved:
                var can_castle = true
                # 間のマスが空いているか、敵の利きがないか確認
                for x in range(pos.x + 1, rook_pos.x):
                    if board[x][pos.y] != null or _is_square_attacked(Vector2(x, pos.y), piece.player):
                        can_castle = false
                        break
                
                if can_castle:
                    moves.append(Vector2(pos.x + 2, pos.y))
        
        # クイーンサイドキャスリング
        if castling_rights[piece.player]["queenside"]:
            var rook_pos = Vector2(0, pos.y)
            var rook = get_piece_at(rook_pos)
            if rook and rook.type == Globals.PieceType.ROOK and not rook.has_moved:
                var can_castle = true
                # 間のマスが空いているか確認
                for x in range(rook_pos.x + 1, pos.x):
                    if board[x][pos.y] != null:
                        can_castle = false
                        break
                
                # 王が通るマスに敵の利きがないか確認
                for x in range(pos.x - 1, pos.x - 3, -1):
                    if _is_square_attacked(Vector2(x, pos.y), piece.player):
                        can_castle = false
                        break
                
                if can_castle:
                    moves.append(Vector2(pos.x - 2, pos.y))
    
    return moves

func _filter_moves_that_prevent_check(piece, moves):
    var valid_moves = []
    var original_pos = piece.board_position
    
    for move in moves:
        # 一時的に移動させてチェック状態を確認
        var captured = get_piece_at(move)
        
        # 移動
        board[original_pos.x][original_pos.y] = null
        piece.board_position = move
        board[move.x][move.y] = piece
        
        # チェック状態の確認
        var king = _find_king(piece.player)
        var is_in_check = king != null and _is_square_attacked(king.board_position, piece.player)
        
        # 元に戻す
        board[move.x][move.y] = captured
        piece.board_position = original_pos
        board[original_pos.x][original_pos.y] = piece
        
        # チェックを回避できる移動のみ追加
        if not is_in_check:
            valid_moves.append(move)
    
    return valid_moves

func _find_king(player):
    for x in range(Globals.BOARD_SIZE):
        for y in range(Globals.BOARD_SIZE):
            var piece = board[x][y]
            if piece and piece.type == Globals.PieceType.KING and piece.player == player:
                return piece
    return null

func _is_square_attacked(pos, defender_player):
    var attacker_player = Globals.Player.BLACK if defender_player == Globals.Player.WHITE else Globals.Player.WHITE
    
    # ポーンの攻撃
    var pawn_directions = [Vector2(-1, -1), Vector2(1, -1)] if attacker_player == Globals.Player.BLACK else [Vector2(-1, 1), Vector2(1, 1)]
    for dir in pawn_directions:
        var attacker_pos = Vector2(pos.x + dir.x, pos.y + dir.y)
        if _is_valid_position(attacker_pos):
            var attacker = board[attacker_pos.x][attacker_pos.y]
            if attacker and attacker.type == Globals.PieceType.PAWN and attacker.player == attacker_player:
                return true
    
    # ナイトの攻撃
    var knight_offsets = [
        Vector2(1, 2), Vector2(2, 1), Vector2(2, -1), Vector2(1, -2),
        Vector2(-1, -2), Vector2(-2, -1), Vector2(-2, 1), Vector2(-1, 2)
    ]
    for offset in knight_offsets:
        var attacker_pos = Vector2(pos.x + offset.x, pos.y + offset.y)
        if _is_valid_position(attacker_pos):
            var attacker = board[attacker_pos.x][attacker_pos.y]
            if attacker and attacker.type == Globals.PieceType.KNIGHT and attacker.player == attacker_player:
                return true
    
    # 縦横の攻撃（ルーク、クイーン）
    var orthogonal_directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
    for dir in orthogonal_directions:
        var current = Vector2(pos.x + dir.x, pos.y + dir.y)
        while _is_valid_position(current):
            var attacker = board[current.x][current.y]
            if attacker:
                if attacker.player == attacker_player and (attacker.type == Globals.PieceType.ROOK or attacker.type == Globals.PieceType.QUEEN):
                    return true
                break
            current = Vector2(current.x + dir.x, current.y + dir.y)
    
    # 斜めの攻撃（ビショップ、クイーン）
    var diagonal_directions = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
    for dir in diagonal_directions:
        var current = Vector2(pos.x + dir.x, pos.y + dir.y)
        while _is_valid_position(current):
            var attacker = board[current.x][current.y]
            if attacker:
                if attacker.player == attacker_player and (attacker.type == Globals.PieceType.BISHOP or attacker.type == Globals.PieceType.QUEEN):
                    return true
                break
            current = Vector2(current.x + dir.x, current.y + dir.y)
    
    # キングの攻撃（1マス隣接）
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if dx == 0 and dy == 0:
                continue
                
            var attacker_pos = Vector2(pos.x + dx, pos.y + dy)
            if _is_valid_position(attacker_pos):
                var attacker = board[attacker_pos.x][attacker_pos.y]
                if attacker and attacker.type == Globals.PieceType.KING and attacker.player == attacker_player:
                    return true
    
    return false

func is_in_check(player):
    var king = _find_king(player)
    if not king:
        return false
    
    return _is_square_attacked(king.board_position, player)

func is_checkmate(player):
    if not is_in_check(player):
        return false
    
    # プレイヤーの全ての駒について有効な移動があるか確認
    for piece in get_player_pieces(player):
        if not get_valid_moves(piece).empty():
            return false
    
    return true

func is_stalemate(player):
    if is_in_check(player):
        return false
    
    # プレイヤーの全ての駒について有効な移動があるか確認
    for piece in get_player_pieces(player):
        if not get_valid_moves(piece).empty():
            return false
    
    # 持ち駒があり、配置可能な場所があるか確認
    if not captured_pieces[player].empty():
        for x in range(Globals.BOARD_SIZE):
            for y in range(Globals.BOARD_SIZE):
                if board[x][y] == null:
                    var pos = Vector2(x, y)
                    
                    # 置ける持ち駒があるかチェック
                    for piece in captured_pieces[player]:
                        if piece.type == Globals.PieceType.PAWN and (y == 0 or y == 7):
                            continue  # ポーンは端には置けない
                        
                        # 一時的に駒を配置してチェックを避けられるか確認
                        board[x][y] = piece
                        var king = _find_king(player)
                        var is_in_check = king != null and _is_square_attacked(king.board_position, player)
                        board[x][y] = null
                        
                        if not is_in_check:
                            return false
    
    return true

func _update_castling_rights(piece):
    if piece.type == Globals.PieceType.KING:
        castling_rights[piece.player]["kingside"] = false
        castling_rights[piece.player]["queenside"] = false
    elif piece.type == Globals.PieceType.ROOK:
        var pos = piece.board_position
        if pos.x == 0:  # クイーンサイドのルーク
            castling_rights[piece.player]["queenside"] = false
        elif pos.x == 7:  # キングサイドのルーク
            castling_rights[piece.player]["kingside"] = false

func _is_castling_move(piece, to_pos):
    if piece.type != Globals.PieceType.KING:
        return false
    
    var from_pos = piece.board_position
    return abs(from_pos.x - to_pos.x) > 1

func _is_en_passant_move(piece, to_pos):
    if piece.type != Globals.PieceType.PAWN:
        return false
    
    var from_pos = piece.board_position
    if en_passant_target and to_pos == en_passant_target:
        return abs(from_pos.x - to_pos.x) == 1 and board[to_pos.x][to_pos.y] == null
    
    return false

func _is_valid_position(pos):
    return pos.x >= 0 and pos.x < Globals.BOARD_SIZE and pos.y >= 0 and pos.y < Globals.BOARD_SIZE

func _get_current_player():
    var white_count = 0
    var black_count = 0
    
    for piece in get_all_pieces