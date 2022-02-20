{-# LANGUAGE OverloadedStrings, ScopedTypeVariables #-}
module InterfaceLib where

import AdditionLib

import qualified Graphics.UI.FLTK.LowLevel.FL as FL
import Graphics.UI.FLTK.LowLevel.Fl_Types
import Graphics.UI.FLTK.LowLevel.FLTKHS
import Graphics.UI.FLTK.LowLevel.Fl_Enumerations
import Control.Monad
import Data.IORef
import Data.Either
import qualified Data.ByteString as B
import Data.Text (pack, Text)

--Дополнительные функции для интерефейса тут
--Сделать проверку на меньшие поля в большом поле

data WindowConfig =
    WC
    {
        width :: Int,
        height :: Int
    }
data CellsConfig =
    CC
    {
        cellSize :: Int,
        cntInRow :: IORef Int,
        cellToWin :: IORef Int
    }

data MainGUI =
  MG
  {
    cllsCnf :: CellsConfig,
    windCnf :: WindowConfig,
    mainWindow :: Ref Window,
    packs :: Ref Group
  }
data HardField =
  HF
  {
    field ::[Ref Button],
    state :: GameState,
    player :: Player
  }
data SimpleField =
  SF
  {
    fieldBtns :: [Ref Button],
    labelInfo :: Ref Box,
    rowCnt :: Int,
    group :: Ref Group
  }
type FieldNumber = Int
type ButtonNumber = Int

data ButtonData =
  BD
  {
    fieldN :: FieldNumber,
    btnN :: ButtonNumber
  }
data SettingsData =
  SD
  {
    cellsToWin :: IORef Int,
    cellsInField :: IORef Int
  }

defaultColor :: RGB
defaultColor = (0,0,0)
crossColor :: RGB
crossColor = (155,17,30)
zeroColor :: RGB
zeroColor = (14,19,236)
crossColor' :: RGB
crossColor' = (214,120,130)
zeroColor' :: RGB
zeroColor' = (98,101,224)
backGroundColor :: RGB
backGroundColor = (47, 110, 147)

plToColorFont :: Player -> RGB
plToColorFont Cross = crossColor
plToColorFont Zero = zeroColor
plToColorFont _ = defaultColor
plToColorBack :: Player -> RGB
plToColorBack Cross = crossColor'
plToColorBack Zero = zeroColor'
plToColorBack _ = defaultColor


newButton :: Int -> Int -> Int -> Int -> Maybe Text -> IO (Ref Button)
newButton xPos yPos xSize ySize = buttonNew
            (Rectangle (Position (X xPos) (Y yPos)) (Size (Width xSize) (Height ySize)))


newLabel :: Int -> Int -> Int -> Int -> Maybe Text -> IO (Ref Box)
newLabel xPos yPos xSize ySize = boxNew
            (Rectangle (Position (X xPos) (Y yPos)) (Size (Width xSize) (Height ySize)))


newButtonState :: Ref Button -> IORef Player -> IO ()
newButtonState b' pl = do
  currentPlayer <- readIORef pl
  setLabel b' (pack $ plT currentPlayer)
  switchColorPlayer currentPlayer b'
  writeIORef pl (rPl currentPlayer)


switchColorPlayer :: Player -> Ref Button -> IO ()
switchColorPlayer player widget =
  rgbColorWithRgb (plToColorFont player) >>= setLabelcolor widget


changeButtonBlockColor :: [Ref Button] -> Player -> IO ()
changeButtonBlockColor btns pl = mapM_ helper btns
  where
    helper :: Ref Button -> IO ()
    helper b' =
      rgbColorWithRgb (plToColorBack pl) >>= setColor b' >>
      rgbColorWithRgb (plToColorBack pl) >>= setDownColor b' >>
      hide b' >>
      showWidget b'


settingsScreen :: MainGUI -> IORef Int -> IORef Int -> IO ()
settingsScreen gui cellsToWin cellsCount = do
     let winWidth  = width (windCnf gui) `div` 2
     let winHeight = height (windCnf gui) `div` 4 *3
     minCells <- newIORef 3
     maxCells <- newIORef 8
     cellTOWin <-readIORef cellsToWin
     cellCount <- readIORef cellsCount
     let textcntCells = "Count of cells in field: "
     let textcntToWinCells = "Count of cells to win: "

     win <- overlayWindowNew (Size (Width winWidth) (Height winHeight))
                              Nothing
                              Nothing
                              winFunc
     setModal win
     clearBorder win
     showWidget win
     begin win

     cntCells    <- newLabel  80 40 100 30 (Just $ pack $ textcntCells ++ show cellCount)
     addCntCells <- newButton 230 30 20 20 (Just "+")
     decCntCells <- newButton 230 50 20 20 (Just "-")

     cntCellsToWin   <- newLabel 80 140 100 30 (Just $ pack $ textcntToWinCells ++ show cellTOWin)
     addCntCellsToWin <- newButton 230 130 20 20(Just "+")
     decCntCellsToWin <- newButton 230 150 20 20(Just "-")

     setLabelsize decCntCells (FontSize 10)
     setLabelsize addCntCells (FontSize 10)
     setLabelsize cntCells (FontSize 16)
     setLabelsize decCntCellsToWin (FontSize 10)
     setLabelsize addCntCellsToWin (FontSize 10)
     setLabelsize cntCellsToWin (FontSize 16)


     setCallback decCntCells (decCells textcntCells cellsToWin cellsCount cntCells)
     setCallback addCntCells (addCells textcntCells maxCells cellsCount cntCells)

     setCallback decCntCellsToWin (decCells textcntToWinCells minCells cellsToWin cntCellsToWin)
     setCallback addCntCellsToWin (addCells textcntToWinCells cellsCount cellsToWin cntCellsToWin)

     exitButton <- newButton (winWidth-20) 0 20 20 (Just "X")
     setCallback exitButton (closeWin win)
     end win
     return ()

     where
      winFunc ::Ref OverlayWindow -> IO ()
      winFunc = hide
      closeWin :: Ref OverlayWindow -> Ref Button -> IO ()
      closeWin win b' = destroy win

      decCells :: [Char] -> IORef Int -> IORef Int -> Ref Box -> Ref Button -> IO ()
      decCells txt min cnt label _ = do
        cnt' <- readIORef cnt
        minC <- readIORef min
        when (cnt' > minC) $ do
          writeIORef cnt (cnt'-1)
          setLabel label (pack $ txt ++ show (cnt'-1))
          updateWid label
      addCells :: [Char] -> IORef Int -> IORef Int -> Ref Box -> Ref Button -> IO ()
      addCells txt max cnt label _ = do
        cnt' <- readIORef cnt
        maxC <- readIORef max
        when (cnt' < maxC) $ do
          modifyIORef cnt (+1)
          setLabel label (pack $ txt ++ show (cnt'+1))
          updateWid label
      updateWid :: Ref Box -> IO ()
      updateWid widg = hide widg >> showWidget widg


deactivateField :: [Ref Button] -> IO ()
deactivateField = mapM_ deactivate


activateField :: [Ref Button] -> IO ()
activateField = mapM_ activate


readCells :: [Ref Button] -> Int -> IO [Player]
readCells cellList inRow = do
  fieldIO <- newIORef ([] :: [Player])
  mapM_ (getLabel >=> (\d -> modifyIORef fieldIO (++ [pl d]))) cellList
  readIORef fieldIO


checkDraw :: [Player] -> GameState
checkDraw field
  | cntNaPs == 0 = Draw
  | otherwise = Game
  where
    cntNaPs = length $ filter (==NaP) field


cleanAllCells :: [Ref Button] -> IO ()
cleanAllCells = mapM_ helper
  where
    helper s = setLabel s "" >>= \m -> switchColorPlayer NaP s


cleanHardField :: IORef [HardField] -> IO ()
cleanHardField fieldIO = do
  fields <- readIORef fieldIO
  writeIORef fieldIO ([] :: [HardField])
  forM_ [0..8] $ \i -> do
    mapM_ helper (field (fields !! i))
    modifyIORef fieldIO (++[HF{field = field (fields !! i), state = Game, player = NaP}])
  where
    helper :: Ref Button -> IO ()
    helper s = setLabel s "" >>
     (setColor s backgroundColor >>
     (setDownColor s backgroundColor >>
     activate s))


refactorList :: [a] -> Int -> [[a]]
refactorList lst inRow = recur lst inRow 0 [] []
    where
        recur :: [a] -> Int -> Int -> [a] -> [[a]] -> [[a]]
        recur lst inRow cur buff res
                    | null lst = res ++ [buff]
                    | cur /= inRow = recur (tail lst) inRow (cur+1) (buff ++ [head lst]) res
                    | otherwise = recur lst inRow 0 [] (res ++ [buff])


--TODO 
--Отдельным блоком ✓
--Возможность контролировать весь интерфейс ✓ 
--Красиво и нарядно (30%)
--Обьединить блоки и сделать их универсальными\\//
winWidget :: MainGUI -> SimpleField -> Player -> IO ()
winWidget gui field player = do
  when debugging $ print ("Winner is " ++ plT player)
  cleanAllCells (fieldBtns field)
  winWindow gui field player
  where
    winWindow :: MainGUI -> SimpleField -> Player -> IO ()
    winWindow gui field player = do
     win <- overlayWindowNew (Size (Width $ width (windCnf gui) `div` 2) (Height $ height (windCnf gui) `div` 4))
                              Nothing
                              Nothing
                              (winFunc field)
     setModal win
     clearBorder win
     begin win
     infoLabel  <- newLabel ((width (windCnf gui) `div` 2 - width (windCnf gui) `div` 3) `div` 2)
                             10
                             (width (windCnf gui) `div` 3)
                             (height (windCnf gui) `div` 10)
                             (Just $ pack $ "Winner is " ++ plT player) --Переделать это окно на красиво богато

     pushBtn <- newButton
                ((width (windCnf gui) `div` 2 - width (windCnf gui) `div` 3) `div` 2)
                (height (windCnf gui) `div` 4 - height (windCnf gui) `div` 16)
                (width (windCnf gui) `div` 3)
                (height (windCnf gui) `div` 16)
                (Just "Da?")

     setCallback pushBtn (btnFunc win)
     showWidget win
     end win

     return ()
    btnFunc :: Ref OverlayWindow -> Ref Button -> IO ()
    btnFunc win b' = destroy win
    winFunc :: SimpleField -> Ref OverlayWindow -> IO ()
    winFunc field win = activate (group field)


--TODO 
--Отдельным блоком ✓
--Возможность контролировать весь интерфейс ✓
--Красиво и нарядно (30%)
--Обьединить блоки и сделать их универсальными\\//
drawWidget :: MainGUI -> SimpleField -> IO ()
drawWidget gui field = do
  when debugging $ print "DRAW"
  cleanAllCells (fieldBtns field)
  drawWindow gui field
  where
    drawWindow :: MainGUI -> SimpleField -> IO ()
    drawWindow gui field = do
     win <- overlayWindowNew (Size (Width $ width (windCnf gui) `div` 2) (Height $ height (windCnf gui) `div` 4))
                              Nothing
                              Nothing
                              (winFunc field)
     setModal win
     clearBorder win
     begin win
     infoLabel  <- newLabel ((width (windCnf gui) `div` 2 - width (windCnf gui) `div` 3) `div` 2)
                             10
                             (width (windCnf gui) `div` 3)
                             (height (windCnf gui) `div` 10)
                             (Just "Draw") --Переделать это окно на красиво богато

     pushBtn <- newButton
                ((width (windCnf gui) `div` 2 - width (windCnf gui) `div` 3) `div` 2)
                (height (windCnf gui) `div` 4 - height (windCnf gui) `div` 16)
                (width (windCnf gui) `div` 3)
                (height (windCnf gui) `div` 16)
                (Just "Da?")
     setCallback pushBtn (btnFunc win)
     showWidget win
     end win

     return ()
    btnFunc :: Ref OverlayWindow -> Ref Button -> IO ()
    btnFunc win b' = destroy win
    winFunc :: SimpleField -> Ref OverlayWindow -> IO ()
    winFunc field win = activate (group field)


checkWinSimple :: Player -> Int -> Int -> [Ref Button] -> IO GameState
checkWinSimple player block row btnLst = do
   field <- readCells btnLst row
   playerIsWin <- checkWinPlCustom (refactorList field row) row block player
   when debugging $ print $ refactorList field row
   return $ gState playerIsWin (checkDraw field)


checkWinHard :: Player -> IORef [HardField] -> IO GameState
checkWinHard playerCur fieldIO = do
   field <- readIORef fieldIO
   fieldBig <- newIORef ([] :: [Player])
   forM_ [0..length field -1] $ \i ->
     if state (field !! i) == Win
       then
         modifyIORef fieldBig (++[player (field !! i)])
        else
         modifyIORef fieldBig (++[NaP])
   fieldW <- readIORef fieldBig
   playerIsWin <- checkWinPlCustom (refactorList fieldW 3) 3 3 playerCur
   when debugging $ print $ "BIG" ++ show(refactorList fieldW 3)
   return $ gState playerIsWin (checkDraw fieldW)


--Больше тестов возможны ошибки
checkWinPlCustom :: (Eq a) => [[a]] -> Int -> Int -> a -> IO GameState
checkWinPlCustom pole inRowIn block player = do
  print block
  iSwin <- newIORef False
  forM_[0..inRowIn-1] (check 1 0 0 >=> (\ s -> modifyIORef iSwin (|| s)))
  forM_[0..inRowIn-1] $ \i -> check 0 i 1 0 >>= (\s -> modifyIORef iSwin (|| s))
  checkDiags >>= \s -> modifyIORef iSwin (|| s)
  iSWinFin <- readIORef iSwin
  if iSWinFin
    then
      return Win
    else
      return Game
  where
    check :: Int -> Int -> Int -> Int -> IO Bool
    check xC offX yC offY = do
      win <- newIORef False
      cnt <- newIORef 0
      forM_[0..inRowIn-1] $ \i -> do
        let x = i * xC + offX
        let y = i * yC + offY
        if pole !! x !! y == player
          then
            modifyIORef cnt (+1)
          else
            writeIORef cnt 0
        cntSym <- readIORef cnt
        when (cntSym == block) $ do
            writeIORef win True
            return ()
      readIORef win
    checkDiags :: IO Bool
    checkDiags = do
        win <- newIORef False
        cnt1 <- newIORef 0
        cnt2 <- newIORef 0
        cnt3 <- newIORef 0
        cnt4 <- newIORef 0
        forM_[0..inRowIn-block] $ \offset ->
          forM_[0..inRowIn-offset-1] $ \y -> do
          let x1 = y + offset
          let x2 = inRowIn-1-y-offset
          if pole !! y !! x1 == player
            then
              modifyIORef cnt1 (+1)
            else
              writeIORef cnt1 0
          if pole !! x1 !! y == player
            then
              modifyIORef cnt3 (+1)
            else
              writeIORef cnt3 0

          if pole !! y !! x2 == player
            then
              modifyIORef cnt2 (+1)
            else
              writeIORef cnt2 0

          if pole !! (y+offset) !! (x2+offset) == player
            then
              modifyIORef cnt4 (+1)
            else
              writeIORef cnt4 0
          cntSym1 <- readIORef cnt1
          cntSym2 <- readIORef cnt2
          cntSym3 <- readIORef cnt3
          cntSym4 <- readIORef cnt4

          when (cntSym1 == block || cntSym2 == block ||
                cntSym3 == block || cntSym4 == block) $ do
              writeIORef win True
              return ()
        readIORef win


createGameCells ::Ref Group -> MainGUI -> Ref Box -> (MainGUI -> SimpleField -> IORef Player -> Ref Button -> IO ()) -> IO [Ref Button]
createGameCells frame gui lb func = do
 lstButtonsIO <- newIORef ([] :: [Ref Button])
 inRow <- readIORef $ cntInRow $ cllsCnf gui
 player <- newIORef Cross
 let padX = (windowWidth - buttonSize * inRow) `div` 2
 let padY = (windowHeight - buttonSize * inRow) `div` 2
 forM_ [0..inRow*inRow-1] $ \i -> do
    button <- newButton (i `mod` inRow*buttonSize + padX) (i `div` inRow*buttonSize + padY) buttonSize buttonSize (Just "")
    setLabelsize button (FontSize (fromIntegral $ buttonSize`div`2))
    modifyIORef lstButtonsIO (++ [button])
 lstButtons <- readIORef lstButtonsIO
 mapM_ (\s -> setCallback s (func gui (SF {fieldBtns = lstButtons,labelInfo = lb, group = frame, rowCnt = inRow}) player)) lstButtons
 return lstButtons
 where
   buttonSize = cellSize $cllsCnf gui
   windowWidth = width $ windCnf gui
   windowHeight = height $ windCnf gui


createHardCells :: MainGUI -> (MainGUI -> IORef [HardField] -> ButtonData -> IORef Player -> Ref Button -> IO ()) -> IO ()
createHardCells gui func = do
  playerTurn <- newIORef (Cross :: Player)
  fieldX <- newIORef ([] :: [[Ref Button]])
  forM_ [1..9] $ \i -> do
    cache <- createHardCellsField gui i
    modifyIORef fieldX (++[cache])
  fl <- readIORef fieldX
  field <- newIORef (writeHardField fl [] :: [HardField])
  forM_ [0..8] $ \i ->
    updateHardCellsFunc field (fl !! i) func i playerTurn gui


writeHardField :: [[Ref Button]] -> [HardField] -> [HardField]
writeHardField btns res
  | not $ null btns = writeHardField (tail btns) (res ++ [HF {field = head btns, state = Game, player = NaP}])
  | otherwise = res


createHardCellsField :: MainGUI -> FieldNumber -> IO [Ref Button]
createHardCellsField gui field = do
  lstButtonsIO <- newIORef ([] :: [Ref Button])
  forM_ [0..2] $ \i ->
    forM_ [0..2] $ \d -> do
      b' <- newButton (padX d) (padY i) (cellSize $ cllsCnf gui) (cellSize $ cllsCnf gui) (Just "")
      setLabelsize b' (FontSize (fromIntegral $ cellSize (cllsCnf gui) `div`2))
      modifyIORef lstButtonsIO (++[b'])
  readIORef lstButtonsIO
  where
    widthW = width $ windCnf gui
    heightW = height $ windCnf gui
    padX i = winPadX + (field-1)`mod`3 * 3 * cellSize (cllsCnf gui) + cellSize (cllsCnf gui) * i + 10 * ((field-1) `mod` 3)
    padY i= winPadY + (field-1)`div`3 * 3 * cellSize (cllsCnf gui) + cellSize (cllsCnf gui) * i + 10 * ((field-1)`div`3)
    winPadX = (widthW  - cellSize (cllsCnf gui) * 9) `div` 2
    winPadY = (heightW - cellSize (cllsCnf gui) * 9) `div` 2


updateHardCellsFunc :: IORef [HardField] -> [Ref Button] -> (MainGUI -> IORef [HardField] -> ButtonData -> IORef Player -> Ref Button -> IO ()) -> FieldNumber -> IORef Player -> MainGUI -> IO ()
updateHardCellsFunc field btns func num pl gui =
  forM_ [0..8] $ \i ->
    setCallback (btns !! i) (func gui field (BD {fieldN = num, btnN = i}) pl)