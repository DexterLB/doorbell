import Data.Char        (isSpace, toLower)
import Data.List.Split  (splitOn)
import Text.Regex.PCRE
import Text.Printf
import Data.Maybe       (fromJust)
import Data.List        (intersperse)

baseNote = 48
baseFreq = 440

fCPU = 1*10**6
fT = fCPU / 16



data Pitch = Pitch Int | Rest deriving (Show)

data Note = Note {
      notePitch     :: Pitch
    , noteOctave    :: Int
    , noteDuration  :: (Int, Bool)
} deriving (Show)

data Opt = Tempo Float | Octave Int | Duration Int | OptError deriving (Show, Eq)


data Opts = Opts {
      optTempo     :: Float
    , optOctave    :: Int
    , optDuration  :: Int
} deriving (Show)


data Chunk = Chunk {
      chunkFreq     :: Float
    , chunkDuration :: Float
} deriving (Show)

type Val = (Int, Int)

formatVal :: Val -> String
formatVal (f, d) = (format f "f") ++ (format d "d")

endVal :: String
endVal = format 0xFF "end"

format :: Int -> String -> String
format val comm = printf "                retlw   0x%02x    ; %s\n" val comm


makeVal :: Chunk -> Val
makeVal c = makeVal' (chunkFreq c) (chunkDuration c)

-- | calculate frequency and duration, and do time-spent-in-interrupts compensation
-- | the arbitrary values are actually counts of assembly instructions
makeVal' :: Float -> Float -> Val
makeVal' freq dur = (freqVal, durVal)
    where freqVal = makeFreqVal freq
          durVal  = round $ (fCPU * dur) / (15 + 11 + (((fromIntegral $ 0xFF - (makeFreqVal freq)) / fT) * dur * 20) + (((0xFF * 3) + 16) * 50))

makeFreqVal :: Float -> Int
makeFreqVal 0 = 0x00
makeFreqVal freq = round $ 0xFF - (fT / freq)

makeChunk :: Opts -> Note -> Chunk
makeChunk opts note = Chunk {
          chunkFreq = makeFreq (notePitch note) (noteOctave note)
        , chunkDuration = makeDuration (noteDuration note) (optTempo opts)
    }

-- | from note "duration" to actual duration
makeDuration :: (Int, Bool) -> Float -> Float
makeDuration (dur, haveDot) bpm
    | haveDot   = (3/2) * time
    | otherwise = time
    where time = 4 / ((fromIntegral dur) * bps)
                 where bps = bpm / 60

-- | from note "pitch" to actual frequency
makeFreq :: Pitch -> Int -> Float
makeFreq Rest _ = 0
makeFreq (Pitch p) o = (2 ** ((fromIntegral n)/12)) * baseFreq
                       where n = ((o * 12) + p) - baseNote

-- | parse the note sequence
getNotes :: Opts -> String -> [Note]
getNotes opts s = map (getNote opts) $ splitOn "," $ map toLower s

getNote :: Opts -> String -> Note
getNote opts s = (makeNote opts) $ head
            $ (s =~ "([0-9]*)([abcdefgp]\\#?)(\\.?)([0-9]*)" :: [[String]])

notes = zip ["c", "c#", "d", "d#", "e", "f", "f#", "g", "g#", "a", "a#", "b"] [-9..2]

makeNote :: Opts -> [String] -> Note
makeNote opts (_:dur:pitch:dot:oct:_) = Note {
    notePitch = makePitch pitch
    , noteDuration = makeDuration dur (not $ null dot)
    , noteOctave = makeOctave oct
}
    where
        makeOctave [] = optOctave opts
        makeOctave o = (read o :: Int)
        makePitch ('p':_) = Rest
        makePitch s = Pitch $ fromJust $ lookup s notes
        makeDuration l dot = (makeDuration' l, dot)
        makeDuration' [] = optDuration opts
        makeDuration' s = (read s :: Int)

-- | eww, fixme
getOpts :: String -> Opts
getOpts s = let l = map getOpt $ splitOn "," $ map toLower s in
       Opts { optTempo = (\(Tempo a) -> a) $ head
                (filter (\a -> case a of Tempo _ -> True; _ -> False) l)
            , optOctave = (\(Octave a) -> a) $ head
                (filter (\a -> case a of Octave _ -> True; _ -> False) l)
            , optDuration = (\(Duration a) -> a) $ head
                (filter (\a -> case a of Duration _ -> True; _ -> False) l)
            }

getOpt :: String -> Opt
getOpt ('b':'=':a) = Tempo (read a :: Float)
getOpt ('d':'=':a) = Duration (read a :: Int)
getOpt ('o':'=':a) = Octave (read a :: Int)
getOpt _ = OptError

-- | Splits a RTTTF string into its 3 sections: [name, opts, notes]
splitSections :: String -> [String]
splitSections s = let l = splitOn ":" s in
                    [trim $ head l] ++ (map (filter $ not . isSpace) $ tail l)

processTune :: String -> String
processTune s = let l = splitSections s in
                let opts = getOpts $ l !! 1; title = l !! 0 in
                let tune = (concat $ map (formatVal . makeVal . (makeChunk opts)) $ getNotes opts (l !! 2)) in
                "; start tune '" ++ title ++ "'\n" ++ tune ++ endVal ++ "; end tune '" ++ title ++ "'\n"

pipe :: String -> String
pipe s = concat $ intersperse "\n\n" $ map processTune $ filter (not. null) $ splitOn "\n" s

main = interact pipe

-- | trims leading and trailing whitespace from string (nicked from wiki)
trim :: String -> String
trim = f . f
   where f = reverse . dropWhile isSpace
