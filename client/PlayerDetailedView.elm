module PlayerDetailedView exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)

import Types exposing (..)
import Uitk

view : Player -> Html a
view player =
    table [class "player-detailed-view"] <| [
        tr [] [
            td [] [text "Name"],
            td [] [text <| player.forename ++ " " ++ player.name]
        ],
        tr [] [
            td [] [text "Age"],
            td [] [text <| toString player.age ]
        ],
        tr [] [
            td [] [text "Favoured Position"],
            td [] [Uitk.playerPositionBadge player]
        ],
        tr [] [
            td [] [text "Skill Average"],
            td [] [text <| Types.playerAvgSkill player]
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
    ] ++ case player.injury of
        0 -> []
        n -> [tr [] [
            td [] [text "Injured"],
            td [] [text <| "Expected recovery in " ++ toString player.injury ++ " days"]
        ]]
