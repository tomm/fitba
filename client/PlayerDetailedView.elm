module PlayerDetailedView exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)

import Types exposing (..)

view : Player -> Html a
view player =
    div [class "half-width"] [
        table [class "player-detailed-view"] [
            tr [] [
                td [] [text "Name"],
                td [] [text player.name]
            ],
            tr [] [
                td [] [text "Shooting"],
                td [] [text <| toString player.shooting]
            ],
            tr [] [
                td [] [text "Passing"],
                td [] [text <| toString player.passing]
            ],
            tr [] [
                td [] [text "Tackling"],
                td [] [text <| toString player.tackling]
            ],
            tr [] [
                td [] [text "Handling"],
                td [] [text <| toString player.handling]
            ],
            tr [] [
                td [] [text "Speed"],
                td [] [text <| toString player.speed]
            ]
        ]
    ]
