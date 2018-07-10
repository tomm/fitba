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
import TeamViewMsg exposing (Msg, Msg(SelectPlayer, MovePosition))

pitchX = 812
pitchY = 1280

-- All non-GK pitch positions. note y=0 (opposition goal line) and y=6 (own goal line) are not permitted
movablePitchPositions : List (Int, Int)
movablePitchPositions = List.concat <| List.map (\x -> List.map (\y -> (x,y)) [1,2,3,4,5]) [0,1,2,3,4]

view : TeamTabState -> Team -> Html Msg
view state team =
  let isActive i = case state.selectedPlayer of
          Just j -> j == i
          Nothing -> False
      playerToDiv i p =
        let clickAction = onClick (SelectPlayer <| Just i)
        in Html.tr [if isActive i then activeTableRowStyle else Html.Attributes.style []] [
             Html.td [clickAction] [text <| toString <| i + 1 ]
           , Html.td [clickAction] [text <| p.name]
           , Html.td [clickAction] [text <| toString <| p.shooting]
           , Html.td [clickAction] [text <| toString <| p.passing]
           , Html.td [clickAction] [text <| toString <| p.tackling]
           , Html.td [clickAction] [text <| toString <| p.handling]
           , Html.td [clickAction] [text <| toString <| p.speed]
        ]
    in
        div [] [
            Html.h2 [] [team.name |> text],
            Html.table
                [Html.Attributes.class "squad-list"] <|
                (
                    Html.tr [] [Html.th [] [text "Pos."],
                    Html.th [] [text "Name"],
                    Html.th [] [text "Shooting"],
                    Html.th [] [text "Passing"],
                    Html.th [] [text "Tackling"],
                    Html.th [] [text "Handling"],
                    Html.th [] [text "Speed"]]
                ) ::
                (List.indexedMap playerToDiv (Array.toList team.players)),

            Svg.svg
                [Svg.Attributes.width "100%", Svg.Attributes.height "100%", viewBox "0 0 812 1280" ]
                ([ 
                    Svg.image
                        [ Svg.Events.onClick <| SelectPlayer Nothing,
                          Svg.Attributes.width "100%", Svg.Attributes.height "100%", Svg.Attributes.xlinkHref "/pitch.png" ]
                        []
                ] ++
                -- players
                (List.take 11 <| Array.toList <| Array.indexedMap (\i (x,y) -> playerOnPitch state team i x y) team.formation)
                ++
                -- pitch positions unused by our formation
                case state.selectedPlayer of
                    Nothing -> []
                    Just 0 -> [] -- can't move goalkeeper
                    Just _ ->
                        List.map
                            (\(x, y) ->
                                    -- XXX why doesn't Array.member exist!
                                    if List.member (x, y) <| List.take 11 <| Array.toList team.formation
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

playerOnPitch : TeamTabState -> Team -> Int -> Int -> Int -> Svg.Svg Msg
playerOnPitch state team playerIdx x y =
    let maybePlayer = Array.get playerIdx team.players
        label =
            case maybePlayer of
                Nothing -> ("Empty!", "red")
                Just player -> (player.name, if state.selectedPlayer == Just playerIdx then "#8080ff" else "white")

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


update : Msg -> Model -> (Model, Cmd RootMsg.Msg)
update msg model =
    case msg of
        SelectPlayer (Just p) ->
            let (newModel, changed) = applySelectPlayer model p
            in (newModel, if changed then Cmds.saveFormation <| newModel.ourTeam else Cmd.none)
        SelectPlayer Nothing -> ({ model | tab = TabTeam { selectedPlayer = Nothing }}, Cmd.none)
        -- move selected player to new position
        MovePosition pos ->
            case model.tab of
                TabTeam state -> case state.selectedPlayer of
                    Nothing -> (model, Cmd.none)
                    Just playerIdx ->
                        let newTeam = movePlayerPosition model.ourTeam playerIdx pos
                        in if newTeam /= model.ourTeam then
                            ({model | ourTeam = newTeam,
                                      tab = TabTeam { selectedPlayer = Nothing} },
                             Cmds.saveFormation <| newTeam)
                           else ({model | tab = TabTeam { selectedPlayer = Nothing }}, Cmd.none)
                _ -> (model, Cmd.none)

movePlayerPosition : Team -> Int -> (Int, Int) -> Team
movePlayerPosition team playerIdx pos =
    -- can't move the goalkeeper!
    if playerIdx == 0 then
        team
    else
        { team | formation = Array.set playerIdx pos team.formation }

applySelectPlayer : Model -> Int -> (Model, Bool)
applySelectPlayer model p =
    case model.tab of
        TabTeam state -> case state.selectedPlayer of
            Nothing -> ({ model | tab = TabTeam { selectedPlayer = Just p }}, False)
            Just q ->
                if p == q then
                    ({ model | tab = TabTeam { selectedPlayer = Nothing }}, False)
                  else
                    ({ model | tab = TabTeam { selectedPlayer = Nothing},
                               ourTeam = swapPlayerPositions (model.ourTeam) p q }, True)
        _ -> (model, False)

arrayDirtyGet : Int -> Array a -> a
arrayDirtyGet i arr = case Array.get i arr of
  Just v -> v
  Nothing -> Debug.crash("arrayDirtyGet failed!")

swapPlayerPositions : Team -> Int -> Int -> Team
swapPlayerPositions team p q =
  let p1 = arrayDirtyGet p team.players
      p2 = arrayDirtyGet q team.players
  in { team | players = Array.set q p1 (Array.set p p2 team.players) }
