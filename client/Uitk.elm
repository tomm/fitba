-- This file uses purecss.io classes.
-- The aim is to avoid putting css-framework-specific stuff anywhere except this file.
module Uitk exposing (view, actionButton, backButton, playerPositionBadge, playerInjuryBadge,
    row, column, responsiveColumn, blockButton, blockButtonRow, crossButton, infoIcon, infoButton)

import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html exposing (..)
import Json.Encode

import Types

blockButtonRow : List (RowColumn a) -> Html a
blockButtonRow columns = div [class "clicky-clicky"] [ row columns ]

blockButton : Int -> a -> String -> RowColumn a
blockButton num24ths action label = 
    column num24ths [div [] [button [class "pure-button", onClick action] [text label]]]

actionButton : a -> String -> Html a
actionButton action label = button [class "pure-button", class "button-action", onClick action] [text label]

infoButton : a -> Html a
infoButton action = button [class "pure-button", class "button-info", onClick action] [text infoIcon]

backButton : a -> Html a
backButton action = button [class "pure-button", class "button-action", onClick action] [text "Back"]

crossButton : a -> Html a
crossButton action = button [class "icon-button", onClick action]
    [span [ class "cross-icon", property "innerHTML" (Json.Encode.string "&#x2716;") ] []]

view : Maybe (Html a) -> Html a -> List (Html a) -> Html a
view maybeButton title content =
    div [class "view"] [
        div [class "view-content"] [
            case maybeButton of
                Just b -> row [
                    column 4 [b],
                    column 20 [Html.h2 [] [title]]
                ]
                Nothing -> row [
                    column 24 [Html.h2 [] [title]]
                ]
            ,
            mainContent content
        ]
    ]
    
mainContent : List (Html a) -> Html a
mainContent = Html.div [class "main-content"]

playerPositionBadge : Types.Player -> Html a
playerPositionBadge player = 
    let pos = Types.playerPositionFormat player.positions
    in Html.span [class "player-position-badge", class <| "player-position-" ++ pos] [text pos]

playerInjuryBadge : Types.Player -> Html a
playerInjuryBadge player =
    if player.injury == 0 then
        Html.span [] []
    else
        Html.span [ class "injury-icon", property "innerHTML" (Json.Encode.string "&#x271a;") ] []


type RowColumn a = RowColumn (Html a)

unpackRowColumn : RowColumn a -> Html a
unpackRowColumn (RowColumn r) = r

infoIcon : String
infoIcon = "ⓘ"

row : List (RowColumn a) -> Html a
row columns = Html.div [class "pure-g"] (List.map unpackRowColumn columns)

column : Int -> List(Html a) -> RowColumn a
column num24ths contents = RowColumn <| Html.div [class <| "pure-u-" ++ toString num24ths ++ "-24"] contents

responsiveColumn : Int -> List(Html a) -> RowColumn a
responsiveColumn num24ths contents =
    RowColumn <| Html.div [class "pure-u-1", class <| "pure-u-md-" ++ toString num24ths ++ "-24"] contents
