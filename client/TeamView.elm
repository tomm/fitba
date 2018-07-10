module TeamView exposing (view, update)

import Array exposing (Array)
import Dict exposing (Dict)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Html exposing (Html, Attribute, div, input, text, ul, li, button)
import Svg
import Svg.Events
import Svg.Attributes exposing (..)

import Cmds
import Model exposing (..)
import Types exposing (..)
import RootMsg
import Styles exposing (..)
import TeamViewTypes exposing (State, Msg, Msg(ViewPlayer, ViewSquad, SelectPlayer, MovePosition),
                               View(SquadView, PlayerView), SquadViewState)
import PlayerDetailedView

pitchX = 812
pitchY = 1280

-- All non-GK pitch positions. note y=0 (opposition goal line) and y=6 (own goal line) are not permitted
movablePitchPositions : List (Int, Int)
movablePitchPositions = List.concat <| List.map (\x -> List.map (\y -> (x,y)) [1,2,3,4,5]) [0,1,2,3,4]

view : State -> Html Msg
view state =
    case state.view of
        PlayerView player ->
            div [] [
                Html.h2 [] [text player.name],
                PlayerDetailedView.view player,
                button [Html.Attributes.class "nav", onClick ViewSquad] [text "Back to listings"]
            ]
        SquadView squadViewState -> 
            let isActive i =
                    case squadViewState.selectedPlayer of
                        Just j -> j == i
                        Nothing -> False
                playerToDiv i p =
                    let selectAction = onClick (SelectPlayer <| Just i)
                        infoAction = onClick (ViewPlayer p)
                    in Html.tr [if isActive i then activeTableRowStyle else Html.Attributes.style []] [
                         Html.td [selectAction] [text <| toString <| i + 1 ]
                       , Html.td [selectAction] [text <| p.name]
                       , Html.td [selectAction] [text <| toString <| p.shooting]
                       , Html.td [selectAction] [text <| toString <| p.passing]
                       , Html.td [selectAction] [text <| toString <| p.tackling]
                       , Html.td [selectAction] [text <| toString <| p.handling]
                       , Html.td [selectAction] [text <| toString <| p.speed]
                       , Html.td [infoAction, Html.Attributes.style [("padding", "0"), ("font-size", "200%")]] [text "ⓘ"]
                    ]
            in
                div [] [
                    Html.h2 [] [state.team.name |> text],
                    Html.table
                        [Html.Attributes.class "squad-list"] <|
                        (Html.tr [] [
                            Html.th [] [text "Pos."],
                            Html.th [] [text "Name"],
                            Html.th [] [text "Shooting"],
                            Html.th [] [text "Passing"],
                            Html.th [] [text "Tackling"],
                            Html.th [] [text "Handling"],
                            Html.th [] [text "Speed"],
                            Html.th [] []
                        ]) ::
                        (List.indexedMap playerToDiv (Array.toList state.team.players)),

                    Svg.svg
                        [Svg.Attributes.width "100%", Svg.Attributes.height "100%", viewBox "0 0 812 1280" ]
                        ([ 
                            Svg.image
                                [ Svg.Events.onClick <| SelectPlayer Nothing,
                                  Svg.Attributes.width "100%", Svg.Attributes.height "100%", Svg.Attributes.xlinkHref "/pitch.png" ]
                                []
                        ] ++
                        -- players
                        (List.take 11
                            <| Array.toList
                            <| Array.indexedMap (
                                \i (x,y) -> playerOnPitch state.team squadViewState i x y) state.team.formation)
                        ++
                        -- pitch positions unused by our formation
                        case squadViewState.selectedPlayer of
                            Nothing -> []
                            Just 0 -> [] -- can't move goalkeeper
                            Just _ ->
                                List.map
                                    (\(x, y) ->
                                            -- XXX why doesn't Array.member exist!
                                            if List.member (x, y) <| List.take 11 <| Array.toList state.team.formation
                                            then Svg.text ""
                                            else emptyPitchPosition (x, y)
                                    )
                                    movablePitchPositions
                                )
                ]

positionCircleRadius = 75

pitchPosPixelPos : (Int, Int) -> (Float, Float)
pitchPosPixelPos (x, y) =
    let
        xpadding = 100.0
        ypadding = 100.0
        xinc = (pitchX - 2*xpadding) / 4
        yinc = (pitchY - 2*ypadding) / 6
    in
        (xpadding + (toFloat x)*xinc, ypadding + (toFloat y)*yinc)

emptyPitchPosition : (Int, Int) -> Svg.Svg Msg
emptyPitchPosition (x, y) =
    let
        (xpos, ypos) = pitchPosPixelPos (x, y)
    in
        Svg.circle [ Svg.Events.onClick (MovePosition (x, y)),
                     cx (toString xpos), cy (toString ypos), r <| toString positionCircleRadius, fill "black", fillOpacity "0.1" ] []

playerOnPitch : Team -> SquadViewState -> Int -> Int -> Int -> Svg.Svg Msg
playerOnPitch team squadViewState playerIdx x y =
    let maybePlayer = Array.get playerIdx team.players
        label =
            case maybePlayer of
                Nothing -> ("Empty!", "red")
                Just player -> (player.name, if squadViewState.selectedPlayer == Just playerIdx then "#8080ff" else "white")

        textAtPlayerPos : (String, String) -> Int -> Int -> Svg.Svg Msg
        textAtPlayerPos (str, color) x y =
            let
                (xpos, ypos) = pitchPosPixelPos (x, y)
            in
                Svg.g
                    []
                    [ Svg.circle
                        [ Svg.Events.onClick (SelectPlayer (Just playerIdx)),
                          cx (toString xpos), cy (toString ypos), r <| toString positionCircleRadius, fill "black", fillOpacity "0.1" ]
                        []
                    , Svg.text_
                        [ Svg.Events.onClick (SelectPlayer (Just playerIdx)),
                          Svg.Attributes.textAnchor "middle", fill color,
                          Svg.Attributes.x (toString xpos), Svg.Attributes.y (toString ypos), Svg.Attributes.fontSize "26" ]
                        [
                            Svg.tspan [Svg.Attributes.x <|toString xpos, dy "-10"] [Svg.text <| toString (playerIdx+1) ],
                            Svg.tspan [Svg.Attributes.x <|toString xpos, dy "30"] [Svg.text str ]
                        ]
                    ]
    in
        textAtPlayerPos label x y


update : Msg -> State -> (State, Cmd RootMsg.Msg)
update msg state =
    case msg of
        ViewSquad -> ({ state | view = SquadView { selectedPlayer = Nothing } }, Cmd.none)
        ViewPlayer player -> ({ state | view = PlayerView player }, Cmd.none)
        SelectPlayer (Just p) ->
            let (newState, changed) = applySelectPlayer state p
            in (newState, if changed then Cmds.saveFormation <| newState.team else Cmd.none)
        SelectPlayer Nothing -> ({ state | view = SquadView { selectedPlayer = Nothing }}, Cmd.none)
        -- move selected player to new position
        MovePosition pos ->
            case state.view of
                SquadView squadView -> case squadView.selectedPlayer of
                    Nothing -> (state, Cmd.none)
                    Just playerIdx ->
                        let newTeam = movePlayerPosition state.team playerIdx pos
                        in if newTeam /= state.team then
                            ({state | team = newTeam,
                                      view = SquadView { selectedPlayer = Nothing} },
                             Cmds.saveFormation <| newTeam)
                           else ({state | view = SquadView { selectedPlayer = Nothing }}, Cmd.none)
                _ -> (state, Cmd.none)

movePlayerPosition : Team -> Int -> (Int, Int) -> Team
movePlayerPosition team playerIdx pos =
    -- can't move the goalkeeper!
    if playerIdx == 0 then
        team
    else
        { team | formation = Array.set playerIdx pos team.formation }

applySelectPlayer : State -> Int -> (State, Bool)
applySelectPlayer state p =
    case state.view of
        SquadView squadView -> case squadView.selectedPlayer of
            Nothing -> ({ state | view = SquadView { selectedPlayer = Just p }}, False)
            Just q ->
                if p == q then
                    ({ state | view = SquadView { selectedPlayer = Nothing }}, False)
                  else
                    ({ state | view = SquadView { selectedPlayer = Nothing},
                               team = swapPlayerPositions (state.team) p q }, True)
        _ -> (state, False)

arrayDirtyGet : Int -> Array a -> a
arrayDirtyGet i arr = case Array.get i arr of
  Just v -> v
  Nothing -> Debug.crash("arrayDirtyGet failed!")

swapPlayerPositions : Team -> Int -> Int -> Team
swapPlayerPositions team p q =
  let p1 = arrayDirtyGet p team.players
      p2 = arrayDirtyGet q team.players
  in { team | players = Array.set q p1 (Array.set p p2 team.players) }
