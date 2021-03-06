{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RebindableSyntax #-}
module Journal where

import FFI
import JQuery hiding (filter, not)
import Fay.Text hiding (head, empty, append, map, null)
import Data.Var
import Model
import Menu
import GoodsList
import Prelude

data Transition = Transition { lid :: LID
                             , good :: Good
                             , me :: Sales
                             , formula :: Formula
                             , date :: Int
                             , status :: Status 
                             } deriving Eq
newtype Formula = Formula Text deriving Eq
newtype LID = LID Text deriving (Eq)
data Status = New | ReadyToSync | Synchronized | Error deriving Eq

class Eventable a
instance Eventable Element

main :: Fay()
main = do
    ready $ initMenu initJournal

initJournal :: Var Sales -> Fay ()
initJournal activeSalesVar = do
    initCalendar
    goodVar <- newVar []
    _ <- subscribeChange goodVar redrawGoods
    transVar <- newVar []
    salesTransVar <- mergeVars' filterBySales Nothing activeSalesVar transVar 
    _ <- subscribeWithOld transVar (syncTransitions transVar)
    _ <- subscribeChange salesTransVar (redrawTransitions $ updateTransitionFormula transVar activeSalesVar)
    lastKeyUpTimestampVar <- now >>= newVar
    signalKeyUp lastKeyUpTimestampVar goodVar
    goodsFilterElement <- goodsFilterInput
    keydown (onGoodsFilterKeyDown transVar goodVar activeSalesVar) goodsFilterElement
    keyup (onkeyUp lastKeyUpTimestampVar goodVar) goodsFilterElement
    _ <- focus goodsFilterElement
    return ()

filterBySales :: Sales -> [Transition] -> [Transition]
filterBySales activeSales ts = filter (\x -> (me x) == activeSales) ts

redrawTransitions :: (LID -> Fay ()) -> [Transition] -> Fay ()
redrawTransitions onEnter transitions = do
    select ("table > tbody > tr[lid]") >>= remove
    mapM_ (appendTransition onEnter) transitions
    _ <- focusFirstErrorOrGoodsFilter transitions
    return ()

focusFirstErrorOrGoodsFilter :: [Transition] -> Fay JQuery
focusFirstErrorOrGoodsFilter transitions = elementToFocus >>= focus
    where elementToFocus = head pretendents
          pretendents = transitionPretendents ++ [goodsFilterInput]
          transitionPretendents = map transInput (filter notSyncronzied transitions) 
          transInput t = transitionInput $ lid t
          notSyncronzied t = not $ status t == Synchronized

appendTransition :: (LID -> Fay()) -> Transition -> Fay ()
appendTransition onEnter t@(Transition lid _ _ _ _ status) = do
    element <- select "#journal"
    _ <- append (renderTransition t) element
    formulaElem <- transitionInput lid
    keydown onKeyDown formulaElem
        where onKeyDown e = when (eventKeyCode e == 13) $ onEnter lid

renderTransition :: Transition -> Text
renderTransition (Transition (LID lid) good _ formula date status) = "<tr lid=" <> lid <> "><td>11.05.09</td><td>" <> name good <> "</td><td><input type='text' class='newTransition " <> errorClass <> "' value=" <> pack (show formula) <> " " <> disabled <> "></td><td><a href='#'>Удалить</a></td></tr>"
    where errorClass = if status == Error then "badTransitionText" else ""
          disabled = if status == Synchronized then "disabled" else ""

onGoodsFilterKeyDown :: Var [Transition] -> Var [Good] -> Var Sales -> Event -> Fay ()
onGoodsFilterKeyDown transVar goodsVar activeSalesVar e = do
    when (keycode > 47 && keycode < 58) addtrans
    where keycode = eventKeyCode e
          emptyFormula = Formula ""
          addtrans = do
            activeSales <- get activeSalesVar
            goods <- get goodsVar
            lid <- guid
            let good = goods !! ((truncate keycode) - 48)
            date <- calendarDate
            modify transVar (\ts -> ts ++ [Transition lid good activeSales emptyFormula date New])
            preventDefault e 

eventKeyCode :: Event -> Double
eventKeyCode = ffi "%1.keyCode"

updateTransitionFormula :: Var [Transition] -> Var Sales -> LID -> Fay ()
updateTransitionFormula transVar activeSalesVar lid = do
    inputText <- transitionInput lid >>= getVal
    activeSales <- get activeSalesVar
    modify transVar (map (updateFormula inputText lid activeSales))
    where updateFormula formula lid activeSales t@(Transition ll good me _ date _)
            | (ll == lid) && (me == activeSales) = Transition ll good me (Formula formula) date ReadyToSync
            | otherwise = t

syncTransitions :: Var [Transition] -> [Transition] -> [Transition] -> Fay ()
syncTransitions vts old new = do
    if (formulasNotChanged || nothingReadyToSync) then return () else (sync vts) $ transitionsToSync new
    where formulas transitions = map formula $ transitionsToSync transitions
          readyToSync t = status t == ReadyToSync
          transitionsToSync t = filter readyToSync t
          nothingReadyToSync = null $ transitionsToSync new
          formulasNotChanged = formulas old == formulas new

sync :: Var [Transition] -> [Transition] -> Fay ()
sync vts transitions = ajaxPost url transitions onSyncSuccess onFail
    where url = "/sync-transitions"
          onSyncSuccess ts = modify vts $ map (updateTransitionStatus ts)

updateTransitionStatus :: [Transition] -> Transition -> Transition
updateTransitionStatus ts t = maybe t repl $ find (\x -> lid x == lid t) ts
    where lids = map lid ts
          repl x = Transition (lid t) (good t) (me t) (formula t) (date t) (status x)

transitionInput :: LID -> Fay JQuery
transitionInput lid = select ("tr[lid = " <> pack (show lid) <> "] > td > input")

transitionTR :: LID -> Fay JQuery
transitionTR lid = select $ "tr[lid = " <> pack (show lid) <> "]"

guid :: Fay LID
guid = do
    n <- now
    return $ LID (pack $ show n)

calendarDate :: Fay Int
calendarDate = ffi "jQuery(':date').data('dateinput').getValue().getTime()"

initCalendar :: Fay ()
initCalendar = ffi "jQuery('#today').dateinput({selectors: true, trigger: true, format: 'dd/mm/yyyy'}).data('dateinput').setValue(0)"

regex :: Text -> Text -> Fay Bool
regex = ffi "new RegExp(%1).test(%2)"

checkTransition :: Text -> Fay Bool
checkTransition text = do
    s <- checkSell text
    i <- checkIncome text
    return (s || i)

checkSell :: Text -> Fay Bool
checkSell = regex "^\\d+\\*\\d+$"

checkIncome :: Text -> Fay Bool
checkIncome = regex "^\\d+\\*\\d+/\\d+$"

removeByLid :: LID -> [Transition] -> [Transition]
removeByLid lid transitions= filter (\(Transition l _ _ _ _ _) -> l == lid) transitions

badTransitionClass :: Text
badTransitionClass = "badTransitionText"
