-- This file uses purecss.io classes.
-- The aim is to avoid putting css-framework-specific stuff anywhere except this file.
module Uitk exposing (view, actionButton, backButton, playerPositionBadge, row, column, responsiveColumn)

import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html exposing (..)
import Json.Encode

import Types

actionButton : a -> String -> Html a
actionButton action label = button [class "pure-button", class "button-action", onClick action] [text label]

backButton : a -> Html a
backButton action = button [class "pure-button", class "button-action", onClick action] [text "Back"]

view : Maybe (Html a) -> String -> List (Html a) -> Html a
view maybeButton title content =
    div [class "view"] [
        div [class "view-content"] [
            case maybeButton of
                Just b -> row [
                    column 4 [b],
                    column 20 [Html.h2 [] [text title]]
                ]
                Nothing -> row [
                    column 24 [Html.h2 [] [text title]]
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

type alias RowColumn a = Html a

row : List (RowColumn a) -> Html a
row columns = Html.div [class "pure-g"] columns

column : Int -> List(Html a) -> RowColumn a
column num24ths = Html.div [class <| "pure-u-" ++ toString num24ths ++ "-24"]

responsiveColumn : Int -> List(Html a) -> RowColumn a
responsiveColumn num24ths = Html.div [class "pure-u-1", class <| "pure-u-md-" ++ toString num24ths ++ "-24"]
