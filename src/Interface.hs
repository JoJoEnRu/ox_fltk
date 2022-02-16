{-# LANGUAGE OverloadedStrings #-}
module Interface where

import AdditionLib
import InterfaceLib
import Logic

import qualified Graphics.UI.FLTK.LowLevel.FL as FL
import Graphics.UI.FLTK.LowLevel.Fl_Types
import Graphics.UI.FLTK.LowLevel.FLTKHS
import Graphics.UI.FLTK.LowLevel.Fl_Enumerations
import Control.Monad
import Control.Concurrent
import Data.IORef
import Data.Text (pack, Text, unpack)

--Файл с отрисовкой игрового интерфейса

exitButton :: MainGUI -> Ref Group -> IO ()
exitButton gui frame = do
  let size = 20
  b' <- newButton 0 0 size size (Just "<-")
  setLabelsize b' (FontSize 12)
  setCallback b' (exitButtonFunc gui frame)


exitButtonFunc :: MainGUI -> Ref Group -> Ref Button -> IO ()
exitButtonFunc gui frame b' = do
  hide frame
  mainMenu gui


--Исправить костыль с лишним кодом | Смена порядка игроков (Работает криво)
gameCellPVE :: [Ref Button] -> Int ->  IORef Player -> Ref Button -> IO ()
gameCellPVE btnLst inRow pla b' = do
  state <- getLabel b'
  currentPlayer <- readIORef pla
  when (state == "") $ do
    newButtonState b' pla
    gameState <- checkWinSimple currentPlayer btnLst inRow
    case gameState of
      Win -> winWidget btnLst currentPlayer
      Draw -> drawWidget btnLst
      Game -> do
        botPlayer <- readIORef pla
        field <- readCells btnLst inRow
        botTurn <- callForBotRandom (refactorList field inRow) botPlayer
        let botCell = refactorList btnLst inRow !! fst botTurn !! snd botTurn
        newButtonState botCell pla
        gameState <- checkWinSimple botPlayer btnLst inRow
        case gameState of
          Win -> winWidget btnLst botPlayer
          Draw -> drawWidget btnLst
          Game -> return ()


gameCellPVP :: [Ref Button] -> Int -> IORef Player -> Ref Button -> IO ()
gameCellPVP btnLst inRow pla b' = do
  state <- getLabel b'
  currentPlayer <- readIORef pla
  when (state == "") $ do
    newButtonState b' pla
    gameState <- checkWinSimple currentPlayer btnLst inRow
    case gameState of
      Win -> winWidget btnLst currentPlayer
      Draw -> drawWidget btnLst
      Game -> return ()


hardCellPVP :: MainGUI -> IORef [HardField] -> ButtonData -> IORef Player -> Ref Button -> IO ()
hardCellPVP gui allFieldIO btnData pl b' = do
  stateB <- getLabel b'
  currentPlayer <- readIORef pl
  begin $ mainWindow gui
  when(stateB == "") $ do
    let currentField = fieldN btnData
    let currentBtn = btnN btnData
    newButtonState b' pl

    allField <- readIORef allFieldIO
    
    --Сделать отдельной функцией активацию/дизактивацию полей
    if state (allField !! currentBtn) /= Game
      then
        forM_ [0..8] $ \i ->
            activateField (field $ allField !! i)
      else do
        forM_ [0..8] $ \i ->
          when (i/= currentBtn) $
            deactivateField (field $ allField !! i)
        activateField (field $ allField !! currentBtn)
    
    smallField <- checkWinSimple currentPlayer (field $ allField !! currentField) 3
    when (smallField /= Game && state (allField !! currentField) == Game) $ do
          writeIORef allFieldIO (changeInList allField (HF {field = field $ allField !! currentField, state = smallField, player = currentPlayer}) currentField)
          changeButtonBlockColor (field $ allField !! currentField) (checkTypeOfGame smallField currentPlayer)
          gameState <- checkWinHard currentPlayer allFieldIO
          case gameState of
            Win -> winWidget (field $ allField !! currentBtn) currentPlayer
            Draw -> drawWidget (field $ allField !! currentBtn)
            Game -> return ()
   where
     checkTypeOfGame x y 
      | x == Draw = NaP 
      | otherwise = y


runHardXOPVP :: MainGUI -> IO ()
runHardXOPVP gui = do
  setLabel (mainWindow gui) "Hard XO PVP"
  begin $ mainWindow gui

  mainframe <- groupNew (toRectangle (0,0,width $ windCnf gui, height $ windCnf gui)) Nothing
  begin mainframe
  _ <- createHardCells gui hardCellPVP
  exitButton gui mainframe

  end mainframe
  end $ mainWindow gui


runSimpleXOPVE :: MainGUI -> IO ()
runSimpleXOPVE gui = do
  setLabel (mainWindow gui) "Simple XO PVE"
  begin $ mainWindow gui

  mainframe <- groupNew (toRectangle (0,0,width $ windCnf gui, height $ windCnf gui)) Nothing
  begin mainframe
  _ <- createGameCells (windCnf gui) (cllsCnf gui) gameCellPVE
  exitButton gui mainframe

  end mainframe
  end $ mainWindow gui


runSimpleXOPVP :: MainGUI -> IO ()
runSimpleXOPVP gui = do
  setLabel (mainWindow gui) "Simple XO PVP"
  begin $ mainWindow gui

  mainframe <- groupNew (toRectangle (0,0,width $ windCnf gui, height $ windCnf gui)) Nothing
  begin mainframe
  _ <- createGameCells (windCnf gui) (cllsCnf gui) gameCellPVP
  exitButton gui mainframe

  end mainframe
  end $ mainWindow gui


startGameMode :: MainGUI -> (MainGUI -> IO ()) -> Ref Button -> IO ()
startGameMode gui func _ = do
  hide $ packs gui
  func gui


mainMenu :: MainGUI -> IO ()
mainMenu gui = do
  setLabel (mainWindow gui) "Main Menu"
  begin $ mainWindow gui
  showWidget $ packs gui
  showWidget $ mainWindow gui
  return ()


decCells :: IORef Int -> Ref Box -> Ref Button -> IO ()
decCells cnt label _ = do
  cnt' <- readIORef cnt
  when (cnt' > 3) $ do
    writeIORef cnt (cnt'-1)
    setLabel label (pack $ show $ cnt'-1)
    return ()


addCells :: IORef Int -> Ref Box -> Ref Button -> IO ()
addCells cnt label _ = do
  cnt' <- readIORef cnt
  when (cnt' < 8) $ do
    modifyIORef cnt (+1)
    setLabel label (pack $ show $ cnt'+1)
    return ()


createMainMenu :: WindowConfig -> IO ()
createMainMenu windowC = do
  window <- windowNew
          (Size (Width $ width windowC) (Height $ height windowC))
          Nothing
          (Just "Main Menu")
  begin window
  cellsCount <- newIORef 3
  let bigButtonWidth = 200
  let smallButtonWidth = 20

  mainframe <- groupNew (toRectangle (0,0,width windowC, height windowC)) Nothing

  begin mainframe
  simplePVPMode <- newButton (width windowC - bigButtonWidth *2) (height windowC `div` 4) bigButtonWidth 50 (Just "Simple XO PVP")
  simplePVEMode <- newButton (width windowC - bigButtonWidth *2) (height windowC `div` 4 + 60) bigButtonWidth 50 (Just "Simple XO PVE")
  hardPVPMode   <- newButton (width windowC - bigButtonWidth *2) (height windowC `div` 4 + 120) bigButtonWidth 50 (Just "Hard XO PVP")

  addCntCells <- newButton (width windowC - smallButtonWidth) 0 smallButtonWidth 20 (Just "+")
  cntCells    <- newLabel (width windowC - smallButtonWidth) 20 smallButtonWidth 20 (Just "3")
  decCntCells <- newButton (width windowC - smallButtonWidth) 40 smallButtonWidth 20 (Just "-")
  end mainframe
  end window

  rgbColorWithRgb (38,104,232)    >>= setColor simplePVPMode --НАЙТИ СПОСОБ МЕНЯТЬ ГРАНИЦЫ
  rgbColorWithRgb (38,104,232)    >>= setDownColor simplePVPMode --НАЙТИ СПОСОБ МЕНЯТЬ ГРАНИЦЫ
  rgbColorWithRgb backGroundColor >>= setColor window

  setLabelsize hardPVPMode (FontSize 20)
  setLabelsize simplePVEMode (FontSize 20)
  setLabelsize simplePVPMode (FontSize 20)

  setLabelsize decCntCells (FontSize 10)
  setLabelsize addCntCells (FontSize 10)
  setLabelsize cntCells (FontSize 10)

  let mainWindow = MG
                    {
                      windCnf = windowC,
                      cllsCnf = CC
                        {
                          cellSize = 50,
                          cntInRow = cellsCount
                        },
                      mainWindow = window,
                      packs = mainframe
                    }

  setCallback simplePVPMode (startGameMode mainWindow runSimpleXOPVP)
  setCallback simplePVEMode (startGameMode mainWindow runSimpleXOPVE)
  setCallback hardPVPMode (startGameMode mainWindow runHardXOPVP)

  setCallback decCntCells (decCells cellsCount cntCells)
  setCallback addCntCells (addCells cellsCount cntCells)

  mainMenu mainWindow
  FL.run
  FL.flush