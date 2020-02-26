module LeagueTableView exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Model exposing (..)
import RootMsg exposing (..)
import Types exposing (..)

view : Model -> LeagueTable -> Html Msg
view model league =
    let recordToTableLine index record =
        Html.tr
            [onClick (ViewTeam record.teamId)] 
            [
                Html.td [] [text <| toString <| index + 1]
              , Html.td [] [text record.name]
              , Html.td [] [record.won + record.drawn + record.lost |> toString |> text]
              , Html.td [] [record.won |> toString |> text]
              , Html.td [] [record.drawn |> toString |> text]
              , Html.td [] [record.lost |> toString |> text]
              , Html.td [] [record.goalsFor |> toString |> text]
              , Html.td [] [record.goalsAgainst |> toString |> text]
              , Html.td [] [record.goalsFor - record.goalsAgainst |> toString |> text]
              , Html.td [] [calcPoints record |> toString |> text]
            ]
    in
        Html.div [] [
            Html.h3 [] [text league.name],
            Html.table [class "league-table"] (
                (Html.tr [] [
                    Html.th [] [text "Pos."]
                  , Html.th [] [text "Team"]
                  , Html.th [] [text "Played"]
                  , Html.th [] [text "Won"]
                  , Html.th [] [text "Drawn"]
                  , Html.th [] [text "Lost"]
                  , Html.th [] [text "GF"]
                  , Html.th [] [text "GA"]
                  , Html.th [] [text "GD"]
                  , Html.th [] [text "Points"]
                ]) ::
                (List.indexedMap recordToTableLine (sortLeague league.record))
            )
        ]

sortLeague : List SeasonRecord -> List SeasonRecord
sortLeague sr =
  let ptsDesc a b = if calcPoints a > calcPoints b then LT else (
      if calcPoints a < calcPoints b then GT else
        (if a.goalsFor - a.goalsAgainst > b.goalsFor - b.goalsAgainst then LT else GT)
      )
                    
  in List.sortWith ptsDesc sr

calcPoints : SeasonRecord -> Int
calcPoints sr = sr.won*3 + sr.drawn*1
