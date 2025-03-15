extends Node

# 戦術・戦法検出システム

var game_state

func _ready():
    game_state = get_parent().get_node("GameState")

func detect_tactics(piece, from_pos, to_pos):
    var tactics = []
    
    # キャスリングの検出
    if _is_castling(piece, from_pos, to_pos):
        tactics.append("castling")
    
    # フォークの検出（2つ以上の駒を同時に攻撃）
    if _is_fork(piece, to_pos):
        tactics.append("fork")
    
    # ピンの検出（駒が動けなくなる）
    if _is_pin(piece, to_pos):
        tactics.append("pin")
    
    # ディスカバードアタックの検出（駒が動くことで別の駒の攻撃ラインが開く）
    if _is_discovered_attack(piece, from_pos, to_pos):
        tactics.append("discovered_attack")
    
    # チェックの検出
    var opponent = Globals.Player.BLACK if piece.player == Globals.Player.WHITE else Globals.Player.WHITE
    if _causes_check(piece, to_pos, opponent):
        tactics.append("check")
    
    return tactics

func _is_castling(piece, from_pos, to_pos):
    if piece.type != Globals.PieceType.KING:
        return false
    
    # キングが横に2マス以上移動した場合はキャスリング
    return abs(from_pos.x - to_pos.x) >= 2

func _is_fork(piece, to_pos):
    var opponent = Globals.Player.BLACK if piece.player == Globals.Player.WHITE else Globals.Player.WHITE
    var threatened_pieces = 0
    
    # 一時的に駒を移動
    var original_piece = game_state.board[to_pos.x][to_pos.y]
    var original_pos = piece.board_position
    
    game_state.board[original_pos.x][original_pos.y] = null
    piece.board_position = to_pos
    game_state.board[to_pos.x][to_pos.y] = piece
    
    # すべての相手の駒について、この駒から攻撃できるか確認
    for x in range(Globals.BOARD_SIZE):
        for y in range(Globals.BOARD_SIZE):
            var target = game_state.board[x][y]
            if target and target.player == opponent:
                if _can_attack(piece, Vector2(x, y)):
                    threatened_pieces += 1
    
    # 元に戻す
    game_state.board[to_pos.x][to_pos.y] = original_piece
    piece.board_position = original_pos
    game_state.board[original_pos.x][original_pos.y] = piece
    
    # 2つ以上の駒を脅かしている場合はフォーク
    return threatened_pieces >= 2

func _is_pin(piece, to_pos):
    var opponent = Globals.Player.BLACK if piece.player == Globals.Player.WHITE else Globals.Player.WHITE
    
    # 一時的に駒を移動
    var original_piece = game_state.board[to_pos.x][to_pos.y]
    var original_pos = piece.board_position
    
    game_state.board[original_pos.x][original_pos.y] = null
    piece.board_position = to_pos
    game_state.board[to_pos.x][to_pos.y] = piece
    
    var opponent_king = _find_king(opponent)
    if not opponent_king:
        # 元に戻して終了
        game_state.board[to_pos.x][to_pos.y] = original_piece
        piece.board_position = original_pos
        game_state.board[original_pos.x][original_pos.y] = piece
        return false
    
    var pinned_pieces = []
    
    # ピンを検出（キングとの間に1つの駒があり、それが動くとキングが攻撃される状態）
    if piece.type == Globals.PieceType.QUEEN or piece.type == Globals.PieceType.ROOK or piece.type == Globals.PieceType.BISHOP:
        var directions = []
        
        if piece.type == Globals.PieceType.QUEEN or piece.type == Globals.PieceType.ROOK:
            directions += [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
        
        if piece.type == Globals.PieceType.QUEEN or piece.type == Globals.PieceType.BISHOP:
            directions += [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
        
        for dir in directions:
            var intervening_piece = null
            var current = Vector2(to_pos.x + dir.x, to_pos.y + dir.y)
            
            while _is_valid_position(current):
                var current_piece = game_state.board[current.x][current.y]
                
                if current_piece:
                    if current_piece.player == opponent:
                        if intervening_piece == null:
                            # 最初に見つかった相手の駒
                            intervening_piece = current_piece
                        elif current_piece.type == Globals.PieceType.KING:
                            # 間に1つの駒があり、その先にキングがある場合はピン
                            pinned_pieces.append(intervening_piece)
                            break
                        else:
                            # 2つ以上の駒があるのでこの方向にはピンはない
                            break
                    else:
                        # 自分の駒があるのでこの方向には進めない
                        break
                
                current = Vector2(current.x + dir.x, current.y + dir.y)
    
    # 元に戻す
    game_state.board[to_pos.x][to_pos.y] = original_piece
    piece.board_position = original_pos
    game_state.board[original_pos.x][original_pos.y] = piece
    
    return not pinned_pieces.empty()

func _is_discovered_attack(piece, from_pos, to_pos):
    var opponent = Globals.Player.BLACK if piece.player == Globals.Player.WHITE else Globals.Player.WHITE
    
    # 元の位置を通る攻撃ラインを持つ駒を探す
    var attacking_pieces = []
    
    # 一時的に駒を取り除く
    var temp_piece = game_state.board[from_pos.x][from_pos.y]
    game_state.board[from_pos.x][from_pos.y] = null
    
    # 横方向のチェック
    var directions = [
        Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),  # 縦横（ルーク、クイーン）
        Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)  # 斜め（ビショップ、クイーン）
    ]
    
    for dir in directions:
        var current = Vector2(from_pos.x + dir.x, from_pos.y + dir.y)
        var found_own_piece = false
        var found_target = false
        
        while _is_valid_position(current) and not found_target:
            var current_piece = game_state.board[current.x][current.y]
            
            if current_piece:
                if current_piece.player != opponent:
                    # 自分の駒が見つかった
                    if _can_attack_in_direction(current_piece, dir):
                        found_own_piece = true
                else:
                    # 相手の駒が見つかった（攻撃対象）
                    found_target = true
                    if found_own_piece:
                        attacking_pieces.append(current_piece)
                    break
            
            current = Vector2(current.x + dir.x, current.y + dir.y)
    
    # 元に戻す
    game_state.board[from_pos.x][from_pos.y] = temp_piece
    
    return not attacking_pieces.empty()

func _causes_check(piece, to_pos, opponent):
    var original_piece = game_state.board[to_pos.x][to_pos.y]
    var original_pos = piece.board_position
    
    # 一時的に駒を移動
    game_state.board[original_pos.x][original_pos.y] = null
    piece.board_position = to_pos
    game_state.board[to_pos.x][to_pos.y] = piece
    
    # チェック状態を確認
    var is_check = game_state.is_in_check(opponent)
    
    # 元に戻す
    game_state.board[to_pos.x][to_pos.y] = original_piece
    piece.board_position = original_pos
    game_state.board[original_pos.x][original_pos.y] = piece
    
    return is_check

func _can_attack(piece, target_pos):
    var original_pos = piece.board_position
    
    # 駒の種類に応じて攻撃可能かチェック
    match piece.type:
        Globals.PieceType.PAWN:
            # ポーンは斜め前方にのみ攻撃可能
            var direction = -1 if piece.player == Globals.Player.WHITE else 1
            var dx = target_pos.x - original_pos.x
            var dy = target_pos.y - original_pos.y
            return abs(dx) == 1 and dy == direction
        
        Globals.PieceType.KNIGHT:
            # ナイトは L字型に移動・攻撃
            var dx = abs(target_pos.x - original_pos.x)
            var dy = abs(target_pos.y - original_pos.y)
            return (dx == 1 and dy == 2) or (dx == 2 and dy == 1)
        
        Globals.PieceType.BISHOP:
            # ビショップは斜めに攻撃
            var dx = abs(target_pos.x - original_pos.x)
            var dy = abs(target_pos.y - original_pos.y)
            if dx != dy:
                return false
            
            # 間に駒がないか確認
            var dir_x = 1 if target_pos.x > original_pos.x else -1
            var dir_y = 1 if target_pos.y > original_pos.y else -1
            var current = Vector2(original_pos.x + dir_x, original_pos.y + dir_y)
            
            while current != target_pos:
                if game_state.board[current.x][current.y] != null:
                    return false
                current.x += dir_x
                current.y += dir_y
            
            return true
        
        Globals.PieceType.ROOK:
            # ルークは縦横に攻撃
            if target_pos.x != original_pos.x and target_pos.y != original_pos.y:
                return false
            
            # 間に駒がないか確認
            var dir_x = 0
            var dir_y = 0
            
            if target_pos.x > original_pos.x:
                dir_x = 1
            elif target_pos.x < original_pos.x:
                dir_x = -1
            elif target_pos.y > original_pos.y:
                dir_y = 1
            else:
                dir_y = -1
            
            var current = Vector2(original_pos.x + dir_x, original_pos.y + dir_y)
            
            while current != target_pos:
                if game_state.board[current.x][current.y] != null:
                    return false
                current.x += dir_x
                current.y += dir_y
            
            return true
        
        Globals.PieceType.QUEEN:
            # クイーンは縦横斜めに攻撃（ルーク+ビショップ）
            var dx = abs(target_pos.x - original_pos.x)
            var dy = abs(target_pos.y - original_pos.y)
            
            if dx != 0 and dy != 0 and dx != dy:
                return false
            
            # 間に駒がないか確認
            var dir_x = 0
            var dir_y = 0
            
            if target_pos.x > original_pos.x:
                dir_x = 1
            elif target_pos.x < original_pos.x:
                dir_x = -1
            
            if target_pos.y > original_pos.y:
                dir_y = 1
            elif target_pos.y < original_pos.y:
                dir_y = -1
            
            var current = Vector2(original_pos.x + dir_x, original_pos.y + dir_y)
            
            while current != target_pos:
                if game_state.board[current.x][current.y] != null:
                    return false
                current.x += dir_x
                current.y += dir_y
            
            return true
        
        Globals.PieceType.KING:
            # キングは1マス移動
            var dx = abs(target_pos.x - original_pos.x)
            var dy = abs(target_pos.y - original_pos.y)
            return dx <= 1 and dy <= 1
    
    return false

func _can_attack_in_direction(piece, direction):
    match piece.type:
        Globals.PieceType.ROOK:
            # ルークは縦横方向のみ
            return direction.x == 0 or direction.y == 0
        
        Globals.PieceType.BISHOP:
            # ビショップは斜め方向のみ
            return abs(direction.x) == abs(direction.y)
        
        Globals.PieceType.QUEEN:
            # クイーンは全方向
            return true
    
    return false

func _find_king(player):
    for x in range(Globals.BOARD_SIZE):
        for y in range(Globals.BOARD_SIZE):
            var piece = game_state.board[x][y]
            if piece and piece.type == Globals.PieceType.KING and piece.player == player:
                return piece
    return null

func _is_valid_position(pos):
    return pos.x >= 0 and pos.x < Globals.BOARD_SIZE and pos.y >= 0 and pos.y < Globals.BOARD_SIZE