module HistoryView exposing (view)

import Html exposing (..)
import Model exposing (..)
import RootMsg exposing (..)
import Uitk
import LeagueTableView

view : Model -> Html Msg
view model =
    Uitk.view Nothing (text "Club History")
        <| [
            case model.history of
                Nothing -> div [] [ text "Loading..." ]
                Just history -> div [] [
                    Uitk.row [
                        Uitk.blockButton 2 (ViewHistory (history.season - 1)) "<",
                        Uitk.column 20 [
                            h3 [] [text <| "Season " ++ toString history.season]
                        ],
                        Uitk.blockButton 2 (ViewHistory (history.season + 1)) ">"
                    ],
                    div [] (List.map (LeagueTableView.view model) history.leagues)
                ]
        ]
