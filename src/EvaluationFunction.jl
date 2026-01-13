module EvaluationFunction
using Chess
#values taken from chessprogramming.com
const PST_PAWN = [
     0   0   0   0   0   0   0   0;
    50  50  50  50  50  50  50  50;
    10  10  20  30  30  20  10  10;
     5   5  10  25  25  10   5   5;
     0   0   0  20  20   0   0   0;
     5  -5 -10   0   0 -10  -5   5;
     5  10  10 -20 -20  10  10   5;
     0   0   0   0   0   0   0   0
]

const PST_KNIGHT = [
    -50 -40 -30 -30 -30 -30 -40 -50;
    -40 -20   0   0   0   0 -20 -40;
    -30   0  10  15  15  10   0 -30;
    -30   5  15  20  20  15   5 -30;
    -30   0  15  20  20  15   0 -30;
    -30   5  10  15  15  10   5 -30;
    -40 -20   0   5   5   0 -20 -40;
    -50 -40 -30 -30 -30 -30 -40 -50
]

const PST_BISHOP = [
    -20 -10 -10 -10 -10 -10 -10 -20;
    -10   0   0   0   0   0   0 -10;
    -10   0   5  10  10   5   0 -10;
    -10   5   5  10  10   5   5 -10;
    -10   0  10  10  10  10   0 -10;
    -10  10  10  10  10  10  10 -10;
    -10   5   0   0   0   0   5 -10;
    -20 -10 -10 -10 -10 -10 -10 -20
]

const PST_ROOK = [
     0   0   0   0   0   0   0   0;
     5  10  10  10  10  10  10   5;
    -5   0   0   0   0   0   0  -5;
    -5   0   0   0   0   0   0  -5;
    -5   0   0   0   0   0   0  -5;
    -5   0   0   0   0   0   0  -5;
    -5   0   0   0   0   0   0  -5;
     0   0   0   5   5   0   0   0
]

const PST_QUEEN = [
    -20 -10 -10  -5  -5 -10 -10 -20;
    -10   0   0   0   0   0   0 -10;
    -10   0   5   5   5   5   0 -10;
     -5   0   5   5   5   5   0  -5;
      0   0   5   5   5   5   0  -5;
    -10   5   5   5   5   5   0 -10;
    -10   0   5   0   0   0   0 -10;
    -20 -10 -10  -5  -5 -10 -10 -20
]

const PST_KING_MIDDLEGAME = [
    -30 -40 -40 -50 -50 -40 -40 -30;
    -30 -40 -40 -50 -50 -40 -40 -30;
    -30 -40 -40 -50 -50 -40 -40 -30;
    -30 -40 -40 -50 -50 -40 -40 -30;
    -20 -30 -30 -40 -40 -30 -30 -20;
    -10 -20 -20 -20 -20 -20 -20 -10;
     20  20   0   0   0   0  20  20;
     20  30  10   0   0  10  30  20
]

const PST_KING_ENDGAME = [
    -50 -40 -30 -20 -20 -30 -40 -50;
    -30 -20 -10   0   0 -10 -20 -30;
    -30 -10  20  30  30  20 -10 -30;
    -30 -10  30  40  40  30 -10 -30;
    -30 -10  30  40  40  30 -10 -30;
    -30 -10  20  30  30  20 -10 -30;
    -30 -30   0   0   0   0 -30 -30;
    -50 -30 -30 -30 -30 -30 -30 -50
]
const PIECE_VALUES = Dict(
    PAWN => 100,
    KNIGHT => 320,
    BISHOP => 330,
    ROOK => 500,
    QUEEN => 900,
    KING => 20000
)
mutable struct EvalWeights

    #PST

    pst_weight::Float64

    #pawn structure

    doubled_pawn_penalty::Float64
    isolated_pawn_penalty::Float64
    backward_pawn_penalty::Float64
    passed_pawn_bonus_multiplier::Float64

    #piece evaluation

    bishop_pair_bonus::Float64
    knight_outpost_defended_safe::Float64
    knight_outpost_defended:: Float64
    knight_outpost_safe::Float64
    rook_open_file:: Float64
    rook_half_open_file::Float64
    rook_7th_rank::Float64
    connected_rooks:: Float64
    knight_closed_bonus::Float64
    bishop_open_bonus::Float64
    #mobility

    mobility_knight::Float64
    mobility_bishop::Float64
    mobility_rook::Float64
    mobility_queen::Float64
    
    #trapped pieces

    trapped_bishop_hard:: Float64
    trapped_bishop_soft::Float64
    trapped_rook::Float64
    trapped_knight::Float64
    trapped_queen::Float64

    #kingsafety
    pawn_shield_close::Float64
    pawn_shield_far::Float64
    pawn_shield_missing::Float64
    king_tropism_queen::Float64
    king_tropism_rook::Float64
    king_tropism_minor:: Float64
    king_zone_attack::Float64
    pawn_storm:: Float64

    #center control
    center_control_bonus::Float64
    extended_center_bonus::Float64
    center_pawn_bonus::Float64

    #space adv
    space_bonus::Float64

    #kingactivity endgame
    king_activity_endgame::Float64
    king_centralization_endgame::Float64
    king_pawn_proximity:: Float64
    #passed pawn
    passed_pawn_rank_2:: Float64
    passed_pawn_rank_3::Float64
    passed_pawn_rank_4::Float64
    passed_pawn_rank_5::Float64
    passed_pawn_rank_6::Float64
    passed_pawn_rank_7::Float64
end
function default_weights()
    return EvalWeights(
        # PST
        1.0,
        
        # Pawn structure
        15.0,   # doubled_pawn_penalty
        20.0,   # isolated_pawn_penalty
        12.0,   # backward_pawn_penalty
        1.0,    # passed_pawn_bonus_multiplier
        
        # Piece evaluation
        50.0,   # bishop_pair_bonus
        30.0,   # knight_outpost_defended_safe
        15.0,   # knight_outpost_defended
        10.0,   # knight_outpost_safe
        25.0,   # rook_open_file
        15.0,   # rook_half_open_file
        30.0,   # rook_7th_rank
        20.0,   # connected_rooks
        10.0,   # knight_closed_bonus
        10.0,   # bishop_open_bonus
        
        # Mobility
        4.0,    # mobility_knight
        4.0,    # mobility_bishop
        2.0,    # mobility_rook
        1.0,    # mobility_queen
        
        # Trapped pieces
        100.0,  # trapped_bishop_hard
        50.0,   # trapped_bishop_soft
        50.0,   # trapped_rook
        25.0,   # trapped_knight
        75.0,   # trapped_queen
        
        # King safety
        10.0,   # pawn_shield_close
        5.0,    # pawn_shield_far
        15.0,   # pawn_shield_missing
        5.0,    # king_tropism_queen
        2.0,    # king_tropism_rook
        2.0,    # king_tropism_minor
        10.0,   # king_zone_attack
        3.0,    # pawn_storm
        
        # Center control
        10.0,   # center_control_bonus
        5.0,    # extended_center_bonus
        15.0,   # center_pawn_bonus
        
        # Space advantage
        2.0,    # space_bonus
        
        # King activity endgame
        5.0,    # king_activity_endgame
        10.0,   # king_centralization_endgame
        3.0,  # king_pawn_proximity
        # Passed pawn bonuses 
        10.0,   # passed_pawn_rank_2
        15.0,   # passed_pawn_rank_3
        25.0,   # passed_pawn_rank_4
        40.0,   # passed_pawn_rank_5
        60.0,   # passed_pawn_rank_6
        90.0    # passed_pawn_rank_7
    )
end
WEIGHTS = default_weights()
function set_weights!(weights::EvalWeights)
    global WEIGHTS = weights
end
function load_weights_from_txt(filename::String)
    try
        lines = readlines(filename)
        values = [parse(Float64,strip(l)) for l in lines if !isempty(strip(l))]
        if length(values) != NUM_WEIGHTS
            println("File error number of weights expected $NUM_WEIGHTS num weights in the file $(length(values))")
        end
        return vector_to_weights(values)
    catch ex
        println(stderr,"Error reading file using default weights")
        return default_weights()
    end
end
function weights_to_vector(w::EvalWeights)
    return Float64[
        w.pst_weight,
        w.doubled_pawn_penalty,
        w.isolated_pawn_penalty,
        w.backward_pawn_penalty,
        w.passed_pawn_bonus_multiplier,
        w.bishop_pair_bonus,
        w.knight_outpost_defended_safe,
        w.knight_outpost_defended,
        w.knight_outpost_safe,
        w.rook_open_file,
        w.rook_half_open_file,
        w.rook_7th_rank,
        w.connected_rooks,
        w. knight_closed_bonus,
        w.bishop_open_bonus,
        w.mobility_knight,
        w.mobility_bishop,
        w.mobility_rook,
        w.mobility_queen,
        w.trapped_bishop_hard,
        w.trapped_bishop_soft,
        w.trapped_rook,
        w.trapped_knight,
        w.trapped_queen,
        w.pawn_shield_close,
        w.pawn_shield_far,
        w.pawn_shield_missing,
        w.king_tropism_queen,
        w.king_tropism_rook,
        w.king_tropism_minor,
        w.king_zone_attack,
        w.pawn_storm,
        w.center_control_bonus,
        w.extended_center_bonus,
        w.center_pawn_bonus,
        w.space_bonus,
        w.king_activity_endgame,
        w.king_centralization_endgame,
        w.king_pawn_proximity,
        w.passed_pawn_rank_2,
        w.passed_pawn_rank_3,
        w.passed_pawn_rank_4,
        w.passed_pawn_rank_5,
        w.passed_pawn_rank_6,
        w.passed_pawn_rank_7
    ]
end
function vector_to_weights(v::Vector{Float64})
    return EvalWeights(
        v[1],  v[2],  v[3],  v[4],  v[5],
        v[6],  v[7],  v[8],  v[9],  v[10],
        v[11], v[12], v[13], v[14], v[15],
        v[16], v[17], v[18], v[19], v[20],
        v[21], v[22], v[23], v[24], v[25],
        v[26], v[27], v[28], v[29], v[30],
        v[31], v[32], v[33], v[34], v[35],
        v[36], v[37], v[38], v[39], v[40],
        v[41], v[42], v[43], v[44], v[45] 
    )
end
function get_passed_bonus(rank::Int)
    rank == 2 && return WEIGHTS.passed_pawn_rank_2
    rank == 3 && return WEIGHTS.passed_pawn_rank_3
    rank == 4 && return WEIGHTS.passed_pawn_rank_4
    rank == 5 && return WEIGHTS.passed_pawn_rank_5
    rank == 6 && return WEIGHTS.passed_pawn_rank_6
    rank == 7 && return WEIGHTS.passed_pawn_rank_7
    return 0.0  # rank 1 i 8 - niemożliwe dla pionków
end
NUM_WEIGHTS = 45
function file_to_int(f)
        files = [FILE_A, FILE_B, FILE_C, FILE_D, FILE_E, FILE_F, FILE_G, FILE_H]
        for (i,file) in enumerate(files)
            if f==file
                return i
            end
        end
    return 0
end
function rank_to_int(r)
    ranks = [RANK_1, RANK_2, RANK_3, RANK_4, RANK_5, RANK_6, RANK_7, RANK_8]
    for (i,rank) in enumerate(ranks)
        if r ==rank
            return i
        end
    end
    return 0
end
function is_end_game(board::Chess.Board)
    queens = 0
    # minor_major=0
    for i in 1:64
       piece = Chess.pieceon(board,Chess.Square(i))
       piece_type = Chess.ptype(piece)
       if piece_type==QUEEN
            queens+=1
       end
    #    if piece_type in [ROOK,BISHOP,KNIGHT]
    #     minor_major+=1
    #    end
    end
    return queens == 0
end
function count_material(board::Chess.Board,color)
    total = 0
    for i in 1:64
        piece = Chess.pieceon(board,Chess.Square(i))
        if piece != EMPTY && Chess.pcolor(piece) == color
            piece_type = Chess.ptype(piece)
            if ptype != KING
                total += get(PIECE_VALUES,piece_type,0)
            end
        end
    end
    return total
end
function get_pawn_info(board::Chess.Board)
    white_pawn_squares = squares(Chess.pawns(board,WHITE))
    black_pawn_squares = squares(Chess.pawns(board,BLACK))
    white_pawn_files=Set{Int}()
    black_pawn_files=Set{Int}()
    for sq in white_pawn_squares
        push!(white_pawn_files,file_to_int(Chess.file(sq)))
    end
    for sq in black_pawn_squares
        push!(black_pawn_files,file_to_int(Chess.file(sq)))
    end
    return white_pawn_files,black_pawn_files,white_pawn_squares,black_pawn_squares
end
function material_and_pst(board::Chess.Board)
    score = 0
    endgame=is_end_game(board)
    for i in 1:64
        sq = Chess.Square(i)
        piece = Chess.pieceon(board,sq)
        if piece == EMPTY
            continue
        end
        p_type = Chess.ptype(piece)
        p_color = Chess.pcolor(piece)
        piece_value = get(PIECE_VALUES,p_type,0)
        file_idx = file_to_int(Chess.file(sq))
        rank_idx = rank_to_int(Chess.rank(sq))
        #pst if white pawn is on rank 2 we need to take the values from 7 row of the pst
        table_row = p_color == WHITE ? 9-rank_idx : rank_idx
        pst_value=0
        if p_type ==PAWN
            pst_value = PST_PAWN[table_row,file_idx]
        elseif p_type==BISHOP
            pst_value = PST_BISHOP[table_row,file_idx]
        elseif p_type == KNIGHT
            pst_value = PST_KNIGHT[table_row,file_idx]
        elseif p_type == ROOK
            pst_value = PST_ROOK[table_row,file_idx]
        elseif p_type == QUEEN
            pst_value = PST_QUEEN[table_row,file_idx]
        elseif p_type == KING
            pst_value = endgame ? PST_KING_ENDGAME[table_row,file_idx] : PST_KING_MIDDLEGAME[table_row,file_idx]
        end
        total_value = piece_value + pst_value*WEIGHTS.pst_weight
        score += p_color == WHITE ? total_value : -total_value
    end
    return score
end
function piece_evaluation(board::Chess.Board)
    score = 0
    white_bishops =squares(Chess.bishops(board,WHITE))
    black_bishops = squares(Chess.bishops(board,BLACK))
    white_knights =squares(Chess.knights(board,WHITE))
    black_knights= squares(Chess.knights(board,BLACK))
    white_rooks = squares(Chess.rooks(board,WHITE))
    black_rooks = squares(Chess.rooks(board,BLACK))
    white_pawns=Chess.pawns(board,WHITE)
    black_pawns=Chess.pawns(board,BLACK)
    white_pawn_files, black_pawn_files, _, _ = get_pawn_info(board)
    #pair bonus
    if length(white_bishops)>=2
        score+=WEIGHTS.bishop_pair_bonus
    end
    if length(black_bishops)>=2
        score-=WEIGHTS.bishop_pair_bonus
    end

    #weak bishops
    # for sq in white_bishops
    #     attacks=bishopattacks(board,sq)
    #     mobility = length(squares(attacks))
    #     if mobility<=5
    #         score-=WEIGHTS.bishop
    #     end
    # end
    # for sq in black_bishops
    #     attacks=bishopattacks(board,sq)
    #     mobility = length(squares(attacks))
    #     if mobility<=5
    #         score+=15
    #     end
    # end

    #outpost
    for sq in white_knights 
        file = file_to_int(Chess.file(sq))
        rank = rank_to_int(Chess.rank(sq))
        white_pawns=Chess.pawns(board,WHITE)
        white_defence = [Chess.pawnattacks(WHITE,pawn) for pawn in squares(white_pawns)]
        black_pawns=Chess.pawns(board,BLACK)
        black_attacks=[]
        in_danger = false
        defended=false
        for pawn in squares(black_pawns)
            file = file_to_int(Chess.file(pawn))
            rank =rank_to_int(Chess.rank(pawn))
            append!(black_attacks, squares(Chess.pawnattacks(BLACK, Square((file - 1) * 8 + (8 - rank + 1) + 1))))        end
        if sq in white_defence
            defended = true
        else
            defended = false
        end
        if sq in black_attacks
            in_danger =true
        else
            in_danger = false
        end
        if (rank>=4 && rank<=6)&&(file>=3&&file<=6)
            if defended && !in_danger
                score+=WEIGHTS.knight_outpost_defended_safe
            elseif defended
                score+=WEIGHTS.knight_outpost_defended
            elseif !in_danger
                score+=WEIGHTS.knight_outpost_safe
            end
            
        end
    end
    for sq in black_knights
        file = file_to_int(Chess.file(sq))
        rank = rank_to_int(Chess.rank(sq))
        white_pawns=Chess.pawns(board,WHITE)
        black_pawns=Chess.pawns(board,BLACK)
        black_defence = [Chess.pawnattacks(BLACK,pawn) for pawn in squares(black_pawns)]
        white_attacks=[]
        in_danger = false
        defended=false
        for pawn in white_pawns
            file = file_to_int(Chess.file(pawn))
            rank =rank_to_int(Chess.rank(pawn))
            append!(white_attacks, squares(Chess.pawnattacks(WHITE, Square((file - 1) * 8 + (8 - rank - 1) + 1))))          end
        if sq in black_defence
            defended = true
        else
            defended = false
        end
        if sq in white_attacks
            in_danger =true
        else
            in_danger = false
        end
        if (rank>=3 && rank<=5)&&(file>=3&&file<=6)
            if defended && !in_danger
                score-=WEIGHTS.knight_outpost_defended_safe
            elseif defended
                score-=WEIGHTS.knight_outpost_defended
            elseif !in_danger
                score-=WEIGHTS.knight_outpost_safe
            end
            
        end
    end
    #rooks open files halfopen files
    for sq in white_rooks
        file = file_to_int(Chess.file(sq)) 
        has_own_pawn = file in white_pawn_files
        has_enemy_pawn = file in black_pawn_files
        if !has_own_pawn && !has_enemy_pawn
            score+=WEIGHTS.rook_open_file
        elseif !has_own_pawn
            score+=WEIGHTS.rook_half_open_file
        end
    end
    for sq in black_rooks
        file = file_to_int(Chess.file(sq))
        has_own_pawn = file in black_pawn_files
        has_enemy_pawn = file in white_pawn_files
        if !has_own_pawn && !has_enemy_pawn
            score-=WEIGHTS.rook_open_file
        elseif !has_own_pawn
            score-=WEIGHTS.rook_half_open_file
        end
    end
    ##rooks on rank 7/2
    for sq in white_rooks
        if rank_to_int(Chess.rank(sq))==7
            score+=WEIGHTS.rook_7th_rank
        end
    end
    for sq in black_rooks
        if rank_to_int(Chess.rank(sq))==2
            score-=WEIGHTS.rook_7th_rank
        end
    end
    ##connected rooks
    if length(white_rooks)>=2
        if (white_rooks)[1] in squares(Chess.rookattacks(board,(white_rooks)[2]))
            score+=WEIGHTS.connected_rooks
        end
    end
    if length(black_rooks)>=2
        if (black_rooks)[1] in squares(Chess.rookattacks(board,(black_rooks)[2]))
            score-=WEIGHTS.connected_rooks
        end
    end
    ##knight vs bishop open closed position
    total_pawns = squarecount(white_pawns)+squarecount(black_pawns)
     #in a closed position knights are better
    if total_pawns>=12
        score+=WEIGHTS.knight_closed_bonus*(length(white_knights)-length(black_knights))
    elseif total_pawns<=8
        score+=WEIGHTS.bishop_open_bonus*(length(white_bishops)-length(black_bishops))
    end
    return score
end
function pawn_structure(board::Chess.Board)
    score = 0
    white_pawn_files,black_pawn_files,white_pawn_squares,black_pawn_squares=get_pawn_info(board)
    white_pawn_ranks=Dict{Int,Vector{Int}}()
    black_pawn_ranks=Dict{Int,Vector{Int}}()
    for sq in white_pawn_squares
        f = file_to_int(Chess.file(sq))
        r = rank_to_int(Chess.rank(sq))
        if !haskey(white_pawn_ranks,f)
            white_pawn_ranks[f] = Int[]
        end
        push!(white_pawn_ranks[f],r)
    end
    for sq in black_pawn_squares
        f = file_to_int(Chess.file(sq))
        r = rank_to_int(Chess.rank(sq))
        if !haskey(black_pawn_ranks,f)
            black_pawn_ranks[f] = Int[]
        end
        push!(black_pawn_ranks[f],r)
    end
    #doubled pawns
    for (_,ranks) in white_pawn_ranks
        ##weird tricks
        length(ranks)>1&&(score-= WEIGHTS.doubled_pawn_penalty*(length(ranks)-1))
    end
    for (_,ranks) in black_pawn_ranks
        length(ranks)>1&&(score+= WEIGHTS.doubled_pawn_penalty*(length(ranks)-1))
    end
    #isolated pawns
    for file in keys(white_pawn_ranks)
        !haskey(white_pawn_ranks,file-1) && !haskey(white_pawn_ranks,file+1)&&(score-=WEIGHTS.isolated_pawn_penalty)
    end
    for file in keys(black_pawn_ranks)
        !haskey(black_pawn_ranks,file-1) && !haskey(black_pawn_ranks,file+1)&&(score+=WEIGHTS.isolated_pawn_penalty)
    end
    #passed pawns
    for sq in white_pawn_squares
        file=file_to_int(Chess.file(sq))
        rank=rank_to_int(Chess.rank(sq))
        is_passed= !any(check_file -> haskey(black_pawn_ranks,check_file)&&any(bp_rank->bp_rank>rank,black_pawn_ranks[check_file]),max(1,file-1):min(8,file+1))
        is_passed &&(score+=get_passed_bonus(rank))
    end
    for sq in black_pawn_squares
        file=file_to_int(Chess.file(sq))
        rank=rank_to_int(Chess.rank(sq))
        is_passed= !any(check_file -> haskey(white_pawn_ranks,check_file)&&any(wp_rank->wp_rank<rank,white_pawn_ranks[check_file]),max(1,file-1):min(8,file+1))
        is_passed&&(score-=get_passed_bonus(9-rank))
    end
    #backward pawns
    for (file,ranks) in white_pawn_ranks
        for rank in ranks
            has_left = haskey(white_pawn_ranks,file-1)
            has_right = haskey(white_pawn_ranks,file+1)
            if !has_left && !has_right
                continue
            end
            left_is_ahead = !has_left || all(r->r>rank,white_pawn_ranks[file-1])
            right_is_ahead = !has_right || all(r->r>rank,white_pawn_ranks[file+1])
            if left_is_ahead && right_is_ahead
                score-=WEIGHTS.backward_pawn_penalty
            end
        end
    end
    for (file,ranks) in black_pawn_ranks
        for rank in ranks
            has_left = haskey(black_pawn_ranks,file-1)
            has_right = haskey(black_pawn_ranks,file+1)
            if !has_left && !has_right
                continue
            end
            left_is_ahead = !has_left || all(r->r<rank,black_pawn_ranks[file-1])
            right_is_ahead = !has_right || all(r->r<rank,black_pawn_ranks[file+1])
            if left_is_ahead && right_is_ahead
                score+=WEIGHTS.backward_pawn_penalty
            end
        end
    end
    return score
end
function trapped_pieces(board::Chess.Board)
    score = 0
    white_bishops =squares(Chess.bishops(board,WHITE))
    black_bishops = squares(Chess.bishops(board,BLACK))
    white_knights =squares(Chess.knights(board,WHITE))
    black_knights= squares(Chess.knights(board,BLACK))
    white_rooks=squares(Chess.rooks(board,WHITE))
    black_rooks=squares(Chess.rooks(board,BLACK))
    white_queens=squares(Chess.queens(board,WHITE))
    black_queens=squares(Chess.queens(board,BLACK))
    ##trapped bishop
    for sq in white_bishops
        mobility  =squarecount(Chess.bishopattacks(board,sq))
        if mobility <=2
            score-=WEIGHTS.trapped_bishop_hard
        elseif mobility<=4
            score-=WEIGHTS.trapped_bishop_soft
        end
    end
    for sq in black_bishops
        mobility  =squarecount(Chess.bishopattacks(board,sq))
        if mobility <=2
            score+=WEIGHTS.trapped_bishop_hard
        elseif mobility<=4
            score+=WEIGHTS.trapped_bishop_soft
        end
    end
    #trapped rooks
    for sq in white_rooks
        mobility  =squarecount(Chess.rookattacks(board,sq))
        if mobility <=3
            score-=WEIGHTS.trapped_rook
        end
    end
    for sq in black_rooks
        mobility  =squarecount(Chess.rookattacks(board,sq))
        if mobility <=3
            score+=WEIGHTS.trapped_rook
        end
    end
    ##trapped knight
    for sq in white_knights
        mobility = squarecount(Chess.knightattacks(sq))
        if mobility<=2
            score-=WEIGHTS.trapped_knight
        end
    end
    for sq in black_knights
        mobility = squarecount(Chess.knightattacks(sq))
        if mobility<=2
            score+=WEIGHTS.trapped_knight
        end
    end
    ##trapped queen
    for sq in white_queens
        mobility = squarecount(Chess.queenattacks(board,sq))
        if mobility <=5
            score-=WEIGHTS.trapped_queen
        end
    end
    for sq in black_queens
        mobility = squarecount(Chess.queenattacks(board,sq))
        if mobility <=5
            score+=WEIGHTS.trapped_queen
        end
    end
    return score
end
function king_safety(board::Chess.Board)
    is_end_game(board)&&return 0
    score = 0
    ###PAWN SHIELD
    white_king_sq = squares(Chess.kings(board,WHITE))[1]
    black_king_sq = squares(Chess.kings(board,BLACK))[1]
    white_pawns = (Chess.pawns(board,WHITE))
    black_pawns = (Chess.pawns(board,BLACK))
    white_king_zone = (Chess.kingattacks(white_king_sq))
    black_king_zone = (Chess.kingattacks(black_king_sq))
    white_shield_count = squarecount(white_king_zone ∩ white_pawns)
    score += white_shield_count * WEIGHTS.pawn_shield_close
    #max 3 pawns
    missing_shield_w = 3-white_shield_count
    missing_shield_w>0 && (score-=missing_shield_w*WEIGHTS.pawn_shield_missing)
    black_shield_count = squarecount(black_king_zone ∩ black_pawns)
    score -= black_shield_count * WEIGHTS.pawn_shield_close
    missing_shield_b = 3-black_shield_count
    missing_shield_b>0 && (score+=missing_shield_b*WEIGHTS.pawn_shield_missing)
    ##KING TROPISM
    for sq in squares(Chess.queens(board,BLACK))
        ##closer -> more points for the enemy
        score-=(8-Chess.distance(sq,white_king_sq))*WEIGHTS.king_tropism_queen
    end
    for sq in squares(Chess.rooks(board,BLACK))
        score-=(8-Chess.distance(sq,white_king_sq))*WEIGHTS.king_tropism_rook
    end
    for sq in squares(Chess.bishops(board,BLACK))
        score -=(8-Chess.distance(sq,white_king_sq))*WEIGHTS.king_tropism_minor
    end
    for sq in squares(Chess.knights(board,BLACK))
        score -=(8-Chess.distance(sq,white_king_sq))*WEIGHTS.king_tropism_minor
    end
    #
    for sq in squares(Chess.queens(board,WHITE))
        ##closer -> more points for the enemy
        score+=(8-Chess.distance(sq,black_king_sq))*WEIGHTS.king_tropism_queen
    end
    for sq in squares(Chess.rooks(board,WHITE))
        score+=(8-Chess.distance(sq,black_king_sq))*WEIGHTS.king_tropism_rook
    end
    for sq in squares(Chess.bishops(board,WHITE))
        score +=(8-Chess.distance(sq,black_king_sq))*WEIGHTS.king_tropism_minor
    end
    for sq in squares(Chess.knights(board,WHITE))
        score +=(8-Chess.distance(sq,black_king_sq))*WEIGHTS.king_tropism_minor
    end
    ##KING ZONE attacks
    for sq in squares(white_king_zone)
        Chess.isattacked(board,sq,BLACK) && (score-=WEIGHTS.king_zone_attack)
    end
    for sq in squares(black_king_zone)
        Chess.isattacked(board,sq,WHITE) && (score+=WEIGHTS.king_zone_attack)
    end
    ##PAWN STORM
    wk_file = file_to_int(Chess.file(white_king_sq))
    bk_file = file_to_int(Chess.file(black_king_sq))
    for pawn in squares(black_pawns)
        if abs(file_to_int(Chess.file(pawn))-wk_file)<=1
            score-=(8-Chess.distance(pawn,white_king_sq))*WEIGHTS.pawn_storm
        end
    end
    for pawn in squares(white_pawns)
        if abs(file_to_int(Chess.file(pawn))-bk_file)<=1
            score+=(8-Chess.distance(pawn,black_king_sq))*WEIGHTS.pawn_storm
        end
    end
    return score
end
function center_control(board::Chess.Board)
    score = 0
    center_squares = [SQ_E4,SQ_D4,SQ_E5,SQ_D5]
    white_pawns = squares(Chess.pawns(board,WHITE))
    black_pawns = squares(Chess.pawns(board,BLACK))
    #pawns in center
    for pawn in white_pawns
        if pawn in center_squares
            score+=WEIGHTS.center_pawn_bonus
        end
    end
    for pawn in black_pawns
        if pawn in center_squares
            score-=WEIGHTS.center_pawn_bonus
        end
    end
    #attacks on center
    for sq in center_squares
        Chess.isattacked(board,sq,WHITE)&&(score+=WEIGHTS.center_control_bonus)
        Chess.isattacked(board,sq,BLACK)&&(score-=WEIGHTS.center_control_bonus)
    end
    return score
end
function space_advantage(board::Chess.Board)
    score=0
    white_space= 0 
    black_space = 0
    for i in 1:64
        sq = Chess.Square(i)
        rank = rank_to_int(Chess.rank(sq))
        if rank>=5 && Chess.isattacked(board,sq,WHITE)
            white_space+=1
        end
        if rank<=4 && Chess.isattacked(board,sq,BLACK)
            black_space+=1
        end
    end
    score+=(white_space-black_space)*WEIGHTS.space_bonus
    return score
end
function king_activity_endgame(board::Chess.Board)
    !is_end_game(board) && return 0
    score = 0
    white_king_sq = squares(Chess.kings(board,WHITE))[1]
    black_king_sq = squares(Chess.kings(board,BLACK))[1]
    wk_file = file_to_int(Chess.file(white_king_sq))
    wk_rank = rank_to_int(Chess.rank(white_king_sq))
    bk_file = file_to_int(Chess.file(black_king_sq))
    bk_rank = rank_to_int(Chess.rank(black_king_sq))
    ##king_centralization
    white_king_center_dist = max(abs(wk_file-4.5),abs(wk_rank-4.5))
    black_king_center_dist = max(abs(bk_file-4.5),abs(bk_rank-4.5))
    #if white king is further black gets an advantage
    score+=(black_king_center_dist-white_king_center_dist)*WEIGHTS.king_centralization_endgame

    ##king mobility
    white_king_mobility = squarecount(Chess.kingattacks(white_king_sq))
    black_king_mobility = squarecount(Chess.kingattacks(black_king_sq))
    score+=(white_king_mobility-black_king_mobility)*WEIGHTS.king_activity_endgame

    #kiing proximity to pawns
    white_pawns = squares(Chess.pawns(board,WHITE))
    black_pawns = squares(Chess.pawns(board,BLACK))
    for pawn in white_pawns
        score+=(8-Chess.distance(white_king_sq,pawn))*WEIGHTS.king_pawn_proximity
    end
    for pawn in black_pawns
        score -=(8-Chess.distance(black_king_sq,pawn))*WEIGHTS.king_pawn_proximity
    end
    return score
end
function evaluate(board::Chess.Board)
    score = 0.0
    score+=material_and_pst(board)
    score+=piece_evaluation(board)
    score+=pawn_structure(board)
    score+=trapped_pieces(board)
    score+=king_safety(board)
    score+=center_control(board)
    score+=space_advantage(board)
    score+=king_activity_endgame(board)
    return Chess.sidetomove(board) == WHITE ? score : -score
end
export evaluate, is_end_game
export material_and_pst, piece_evaluation, pawn_structure
export trapped_pieces, king_safety
export center_control, space_advantage, king_activity_endgame
export EvalWeights, default_weights, set_weights!, WEIGHTS
export weights_to_vector, vector_to_weights, NUM_WEIGHTS
export load_weights_from_txt
end#module