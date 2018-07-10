module Uitk exposing (view, actionButton, backButton)

import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html exposing (..)

actionButton : a -> String -> Html a
actionButton action label = button [class "action", onClick action] [text label]

backButton : a -> Html a
backButton action = button [class "circle-button", onClick action] [text "←"]

view : Maybe (Html a) -> String -> List (Html a) -> Html a
view maybeButton title content =
    div [class "view"] [
        case maybeButton of
            Just b -> div [class "title-line"] (b :: [Html.h2 [] [text title]])
            Nothing -> div [class "title-line"] [Html.h2 [] [text title]]
        ,
        mainContent content
    ]
    
mainContent : List (Html a) -> Html a
mainContent = Html.div [class "main-content"]
