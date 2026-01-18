export interface ChessResponse{
    best_move: string;
    score: number;
}
export const getBestMove = async (fen: string, depth: number = 5): Promise<ChessResponse | null> => {
    try{
        const response = await fetch("http://localhost:8081" ,{
            method: "POST",
            headers: {"Content-Type":"application/json"},
            body: JSON.stringify({fen,depth}),
        });
        if (!response.ok) throw new Error("Server Error");
        return await response.json();
    }
    catch(error){
        console.error("Engine failed: ", error);
        return null;
    }

};