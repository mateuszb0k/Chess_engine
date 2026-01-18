import React, { useState, useRef, useEffect } from "react";
import { Chessboard } from "react-chessboard";
import { Chess, Move } from "chess.js"; 
import { getBestMove } from "./api"; 
//react-chess tutorial
interface SquareHandlerArgs {
  square: string;
  piece: string;
}

interface PieceDropHandlerArgs {
  sourceSquare: string;
  targetSquare: string;
  piece: string;
}

const ChessGame = () => {
  const chessGameRef = useRef(new Chess());
  
  const [chessPosition, setChessPosition] = useState(chessGameRef.current.fen());
  const [moveFrom, setMoveFrom] = useState("");
  const [optionSquares, setOptionSquares] = useState({});
  const [isThinking, setIsThinking] = useState(false); 

  const makeEngineMove = async () => {
    const game = chessGameRef.current;
    
    if (game.isGameOver()) return;

    setIsThinking(true);

    try {
      const data = await getBestMove(game.fen(), 6); // depth 5

      if (data && data.best_move && data.best_move !== "none") {
        const moveStr = data.best_move; 
        const from = moveStr.substring(0, 2);
        const to = moveStr.substring(2, 4);
        const promotion = moveStr.length > 4 ? moveStr[4] : "q";

        try {
            game.move({ from, to, promotion });
        } catch (e) {
            console.error("Engine error:", moveStr);
        }
        
        setChessPosition(game.fen());
      }
    } catch (error) {
      console.error("Engine Error:", error);
    } finally {
      setIsThinking(false);
    }
  };

  function getMoveOptions(square: string) {
    const game = chessGameRef.current;
    const moves = game.moves({
      square: square as any,
      verbose: true,
    }) as Move[];

    if (moves.length === 0) {
      setOptionSquares({});
      return false;
    }

    const newSquares: Record<string, React.CSSProperties> = {};
    
    moves.map((move) => {
      newSquares[move.to] = {
        background:
          game.get(move.to as any) &&
          game.get(move.to as any)?.color !== game.get(square as any)?.color
            ? "radial-gradient(circle, rgba(0,0,0,.1) 85%, transparent 85%)" 
            : "radial-gradient(circle, rgba(0,0,0,.1) 25%, transparent 25%)",
        borderRadius: "50%",
      };
      return move;
    });

    newSquares[square] = {
      background: "rgba(255, 255, 0, 0.4)",
    };

    setOptionSquares(newSquares);
    return true;
  }

  function onSquareClick(square: string) {
    if (isThinking) return;

    const game = chessGameRef.current;

    if (!moveFrom) {
      const hasMoveOptions = getMoveOptions(square);
      if (hasMoveOptions) setMoveFrom(square);
      return;
    }

    try {
      const move = game.move({
        from: moveFrom,
        to: square,
        promotion: "q",
      });

      if (move) {
        setChessPosition(game.fen());
        setMoveFrom("");
        setOptionSquares({});
        
        setTimeout(makeEngineMove, 300);
        return;
      }
    } catch {
    }

    const hasMoveOptions = getMoveOptions(square);
    setMoveFrom(hasMoveOptions ? square : "");
  }

  function onPieceDrop(sourceSquare: string, targetSquare: string) {
    if (isThinking) return false;

    const game = chessGameRef.current;

    try {
      const move = game.move({
        from: sourceSquare,
        to: targetSquare,
        promotion: "q",
      });

      if (!move) return false; 

      setChessPosition(game.fen());
      setMoveFrom("");
      setOptionSquares({});


      setTimeout(makeEngineMove, 1000);
      return true;
    } catch {
      return false;
    }
  }

  return (
    <div style={styles.container}>
      <h1>Julia Chess Engine</h1>
      <div style={styles.boardWrapper}>
        <Chessboard
          id="ClickOrDragBoard"
          position={chessPosition}
          onPieceDrop={onPieceDrop}
          onSquareClick={onSquareClick}
          customSquareStyles={optionSquares}
          boardOrientation="white"
        />
      </div>
      <div style={styles.status}>
        {isThinking ? (
          <span style={{color: "orange", fontWeight: "bold"}}>Engine Thinking...</span>
        ) : (
          <span>Your move</span>
        )}
      </div>

      <button
        style={styles.button}
        onClick={() => {
          chessGameRef.current.reset();
          setChessPosition(chessGameRef.current.fen());
          setOptionSquares({});
          setMoveFrom("");
          setIsThinking(false);
        }}
      >
        Reset
      </button>
    </div>
  );
};

const styles = {
  container: {
    display: "flex",
    flexDirection: "column" as const,
    alignItems: "center",
    marginTop: "20px",
    fontFamily: "Arial, sans-serif",
  },
  boardWrapper: {
    width: "70vw",
    maxWidth: "500px",
    height: "auto",
  },
  status: {
    marginTop: "15px",
    fontSize: "18px",
    height: "25px"
  },
  button: {
    marginTop: "15px",
    padding: "10px 20px",
    fontSize: "16px",
    cursor: "pointer",
  }
};

export default ChessGame;