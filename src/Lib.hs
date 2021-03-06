module Lib
  ( randomWord'
  , freshPuzzle
  , runGame
  )
where

import           System.Random                  ( randomRIO )
import           Data.List                      ( intersperse )
import           System.Exit                    ( exitSuccess )
import           Data.Maybe                     ( isJust )
import           Control.Monad                  ( forever )


type WordList = [String]

allWords :: IO WordList
allWords = do
  dict <- readFile "../data/dict.txt"
  return $ lines dict

minWordLength :: Int
minWordLength = 5

maxWordLength :: Int
maxWordLength = 9

gameWords :: IO WordList
gameWords = do
  aw <- allWords
  return (filter gameLength aw)
 where
  gameLength w =
    let l = length (w :: String) in l > minWordLength && l < maxWordLength


randomWord :: WordList -> IO String
randomWord wl = do
  randomIndex <- randomRIO (0, length wl - 1)
  return $ wl !! randomIndex

randomWord' :: IO String
randomWord' = gameWords >>= randomWord

sayHello :: String -> IO ()
sayHello name = putStrLn ("Hi " ++ name ++ "!")

data Puzzle = Puzzle String [Maybe Char] String

instance Show Puzzle where
  show (Puzzle _ discovered guessed) =
    intersperse ' ' (fmap renderPuzzleChar discovered)
      ++ " Guessed so far: "
      ++ guessed

freshPuzzle :: String -> Puzzle
freshPuzzle n = Puzzle n (map (const Nothing) n) []

charInWord :: Puzzle -> Char -> Bool
charInWord (Puzzle w _ _) = (`elem` w)

alreadyGuessed :: Puzzle -> Char -> Bool
alreadyGuessed (Puzzle _ _ g) = (`elem` g)

renderPuzzleChar :: Maybe Char -> Char
renderPuzzleChar Nothing  = '_'
renderPuzzleChar (Just c) = c

fillInCharacter :: Puzzle -> Char -> Puzzle
fillInCharacter (Puzzle word filledInSoFar s) c = Puzzle word
                                                         newFilledInSofar
                                                         (c : s)
 where
  zipper guessed wordChar guessChar =
    if wordChar == guessed then Just wordChar else guessChar
  newFilledInSofar = zipWith (zipper c) word filledInSoFar

handleGuess :: Puzzle -> Char -> IO Puzzle
handleGuess puzzle guess = do
  putStrLn $ "Your guess was: " ++ [guess]
  case (charInWord puzzle guess, alreadyGuessed puzzle guess) of
    (_, True) -> do
      putStrLn
        "You already guessed\
            \ character, pick something else!"
      return puzzle
    (True, _) -> do
      putStrLn
        "This character was in the word,\
        \ filling in the word accordingly."
      return (fillInCharacter puzzle guess)
    (False, _) -> do
      putStrLn "This character wasn't in\
        \ tge wordm try again."
      return (fillInCharacter puzzle guess)

gameOver :: Puzzle -> IO ()
gameOver (Puzzle wordToGuess _ guessed) = if length guessed > 7
  then do
    putStrLn "You lose!"
    putStrLn $ "The word was: " ++ wordToGuess
    exitSuccess
  else return ()

gameWin :: Puzzle -> IO ()
gameWin (Puzzle _ filledInSoFar _) = if all isJust filledInSoFar
  then do
    putStrLn "You win!"
    exitSuccess
  else return ()

runGame :: Puzzle -> IO ()
runGame puzzle = forever $ do
  gameOver puzzle
  gameWin puzzle
  putStrLn $ "Current puzzle is: " ++ show puzzle
  putStr "Guess a letter: "
  guess <- getLine
  case guess of
    [x] -> handleGuess puzzle x >>= runGame
    _   -> putStrLn "You guess must \
        \ be a single character"
