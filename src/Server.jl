using HTTP
using JSON
using Chess
using Serialization
include("Search.jl")
include("EvaluationFunction.jl")
using .Search
using .EvaluationFunction
dir = "resources/weights/best_weights6.txt"
if isfile(dir)
   weights = EvaluationFunction.load_weights_from_txt(dir)
   println("Weights loaded")
else
    println("File not found")
end
function handle_request(req::HTTP.Request)
    headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type"
    ]
    if req.method =="OPTIONS"
        return HTTP.Response(200,headers,"")
    end
    if req.method == "GET"
        return HTTP.Response(200, headers, "Server working")
    end
    try
        body = String(req.body)

        if isempty(body)
            return HTTP.Response(400, headers, "Error: Body is empty")
        end

        data = JSON.parse(body)
        fen = data["fen"]
        depth =get(data,"depth",6)
        println("Got FEN: $fen")
        board = Chess.fromfen(fen)
        score,best_move = Search.search_parallel(board,depth,use_book=true,verbose=false)
        move_str = best_move !== nothing ? Chess.tostring(best_move) : "none"
        response_data = Dict(
            "best_move" =>move_str,
            "score" =>score
        )
        return HTTP.Response(200,headers,JSON.json(response_data))
    catch e
        println("Error: $e")
        return HTTP.Response(500,headers, "Internal Server Error")
    end
end
println("Chess server starting at http://localhost:8081")
HTTP.serve(handle_request,"0.0.0.0",8081)