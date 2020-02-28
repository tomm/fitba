module HistoryView exposing (view)

import FixturesView
import Html exposing (..)
import Html.Attributes exposing (..)
import LeagueTableView
import Model exposing (..)
import RootMsg exposing (..)
import Uitk


view : Model -> Html Msg
view model =
    Uitk.view Nothing (text "Club History") <|
        [ case model.history of
            Nothing ->
                div [] [ text "Loading..." ]

            Just history ->
                div []
                    [ Uitk.row
                        [ Uitk.blockButton 2 (ViewHistory (history.season - 1)) "<"
                        , Uitk.column 20
                            [ h3 [] [ text <| "Season " ++ String.fromInt history.season ]
                            ]
                        , Uitk.blockButton 2 (ViewHistory (history.season + 1)) ">"
                        ]
                    , h3 [] [ text "Cup Finals" ]
                    , table []
                        (List.concatMap
                            (\f ->
                                [ tr []
                                    [ th [ class "center", colspan 3 ] [ text f.tournament ]
                                    ]
                                , tr []
                                    [ td [ class "cup-finals-history" ] [ text f.homeName ]
                                    , td [ class "cup-finals-history" ] [ FixturesView.resultText f ]
                                    , td [ class "cup-finals-history" ] [ text f.awayName ]
                                    ]
                                ]
                            )
                            history.cup_finals
                        )
                    , div [] (List.map (LeagueTableView.view model) history.leagues)
                    ]
        ]
