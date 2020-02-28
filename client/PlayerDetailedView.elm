module PlayerDetailedView exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Types exposing (..)
import Uitk


view : Player -> Html a
view player =
    table [ class "player-detailed-view" ] <|
        [ tr []
            [ td [] [ text "Name" ]
            , td [] [ text <| player.forename ++ " " ++ player.name ]
            ]
        , tr []
            [ td [] [ text "Age" ]
            , td [] [ text <| String.fromInt player.age ]
            ]
        , tr []
            [ td [] [ text "Favoured Position" ]
            , td [] [ Uitk.playerPositionBadge player ]
            ]
        , tr []
            [ td [] [ text "Skill Average" ]
            , td [] [ text <| Types.playerAvgSkill player ]
            ]
        , tr []
            [ td [] [ text "Shooting" ]
            , td [] [ text <| String.fromInt player.shooting ]
            ]
        , tr []
            [ td [] [ text "Passing" ]
            , td [] [ text <| String.fromInt player.passing ]
            ]
        , tr []
            [ td [] [ text "Tackling" ]
            , td [] [ text <| String.fromInt player.tackling ]
            ]
        , tr []
            [ td [] [ text "Handling" ]
            , td [] [ text <| String.fromInt player.handling ]
            ]
        , tr []
            [ td [] [ text "Speed" ]
            , td [] [ text <| String.fromInt player.speed ]
            ]
        ]
            ++ (case player.injury of
                    0 ->
                        []

                    n ->
                        [ tr []
                            [ td [] [ text "Injured" ]
                            , td [] [ text <| "Expected recovery in " ++ String.fromInt player.injury ++ " days" ]
                            ]
                        ]
               )
