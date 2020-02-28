module TeamView exposing (squadList, teamTitle, update, view)

import Array exposing (Array)
import ClientServer
import Html exposing (Attribute, Html, button, div, input, li, text, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import PlayerDetailedView
import RootMsg
import Svg
import Svg.Attributes exposing (..)
import Svg.Events
import TeamViewTypes
    exposing
        ( Msg(..)
        , SquadViewState
        , State
        , View(..)
        )
import Types exposing (..)
import Uitk


pitchX : Float
pitchX =
    812


pitchY : Float
pitchY =
    1280



-- All non-GK pitch positions. note y=0 (opposition goal line) and y=6 (own goal line) are not permitted


movablePitchPositions : List ( Int, Int )
movablePitchPositions =
    List.concat <| List.map (\x -> List.map (\y -> ( x, y )) [ 1, 2, 3, 4, 5 ]) [ 0, 1, 2, 3, 4 ]


teamTitle : Team -> String
teamTitle team =
    case team.manager of
        Nothing ->
            team.name ++ " (A.I. Manager)"

        Just name ->
            team.name ++ " (" ++ name ++ ")"


view : State -> Html Msg
view state =
    case state.view of
        PlayerView player ->
            Uitk.view (Just <| Uitk.backButton ViewSquad)
                (text <| player.forename ++ " " ++ player.name)
                [ Uitk.row
                    [ Uitk.column 12 [ PlayerDetailedView.view player ]
                    , Uitk.column 12 [ Uitk.actionButton (SellPlayer player) "Sell this player" ]
                    ]
                ]

        SquadView squadViewState ->
            let
                formationWidget =
                    Svg.svg
                        [ Svg.Attributes.width "100%", Svg.Attributes.height "95%", viewBox "0 0 812 1280" ]
                        ([ Svg.image
                            [ Svg.Events.onClick <| SelectPlayer Nothing
                            , Svg.Attributes.width "100%"
                            , Svg.Attributes.height "100%"
                            , Svg.Attributes.xlinkHref "/pitch.png"
                            ]
                            []
                         ]
                            ++ -- players
                               (List.take 11 <|
                                    Array.toList <|
                                        Array.indexedMap
                                            (\i ( x, y ) -> playerOnPitch state.team squadViewState i x y)
                                            state.team.formation
                               )
                            ++ -- pitch positions unused by our formation
                               (case squadViewState.selectedPlayer of
                                    Nothing ->
                                        []

                                    Just 0 ->
                                        []

                                    -- can't move goalkeeper
                                    Just pidx ->
                                        (case Array.get pidx state.team.players of
                                            Just selectedPlayer -> List.map
                                                (\( x, y ) ->
                                                    let
                                                        positionSuitsPlayer =
                                                            List.member ( x, y ) selectedPlayer.positions
                                                    in
                                                    -- xxx why doesn't array.member exist!
                                                    if List.member ( x, y ) <| List.take 11 <| Array.toList state.team.formation then
                                                        Svg.text ""

                                                    else
                                                        emptyPitchPosition ( x, y ) positionSuitsPlayer
                                                )
                                                movablePitchPositions
                                            _ -> [] -- Should never happen. want to use Debug.crash
                                        )
                               )
                        )
            in
            Uitk.view Nothing
                (text <| teamTitle state.team)
                [ Uitk.row
                    [ Uitk.responsiveColumn 12
                        [ Html.h3 [] [ text "Squad" ]
                        , squadList True state.team.players squadViewState.selectedPlayer
                        ]
                    , Uitk.responsiveColumn 12
                        [ Html.h3 [] [ text "Formation" ]
                        , formationWidget
                        ]
                    ]
                ]


squadList : Bool -> Array Player -> Maybe Int -> Html Msg
squadList infoIconEnabled players selectedPlayerIdx =
    let
        isActive i =
            case selectedPlayerIdx of
                Just j ->
                    j == i

                Nothing ->
                    False

        rowStyle p i =
            if isActive i then
                [ Html.Attributes.class "active-table-row-style" ]

            else
                []
                    ++ (if p.injury > 0 then
                            [ Html.Attributes.class "player-row-injury" ]

                        else
                            []
                       )

        playerToDiv i p =
            let
                selectAction =
                    onClick (SelectPlayer <| Just i)

                infoAction =
                    onClick (ViewPlayer p)
            in
            Html.tr (rowStyle p i) <|
                [ Html.td [ selectAction ] [ text <| String.fromInt <| i + 1 ]
                , Html.td [ selectAction ] [ Uitk.playerPositionBadge p, Uitk.playerInjuryBadge p ]
                , Html.td [ selectAction ] [ text <| p.name ]
                , Html.td [ selectAction ] [ text <| Types.playerAvgSkill p ]
                , Html.td [ selectAction ] [ text <| (\form -> "+" ++ String.fromInt form) <| p.form ]
                , Html.td [ selectAction ] [ text <| String.fromInt <| p.shooting ]
                , Html.td [ selectAction ] [ text <| String.fromInt <| p.passing ]
                , Html.td [ selectAction ] [ text <| String.fromInt <| p.tackling ]
                , Html.td [ selectAction ] [ text <| String.fromInt <| p.handling ]
                , Html.td [ selectAction ] [ text <| String.fromInt <| p.speed ]
                ]
                    ++ (if infoIconEnabled then
                            [ Html.td [ infoAction, Html.Attributes.style "padding" "0", Html.Attributes.style "font-size" "200%" ] [ text Uitk.infoIcon ] ]

                        else
                            []
                       )
    in
    Html.table [ Html.Attributes.class "squad-list" ] <|
        (Html.tr [] <|
            [ Html.th [] [ text "No." ]
            , Html.th [] [ text "Pos." ]
            , Html.th [] [ text "Name" ]
            , Html.th [] [ text "Avg." ]
            , Html.th [] [ text "Form" ]
            , Html.th [] [ text "Sh" ]
            , Html.th [] [ text "Pa" ]
            , Html.th [] [ text "Ta" ]
            , Html.th [] [ text "Ha" ]
            , Html.th [] [ text "Sp" ]
            ]
                ++ (if infoIconEnabled then
                        [ Html.th [] [] ]

                    else
                        []
                   )
        )
            :: List.indexedMap playerToDiv (Array.toList players)


positionCircleRadius : Float
positionCircleRadius =
    75


pitchPosPixelPos : ( Int, Int ) -> ( Float, Float )
pitchPosPixelPos ( x, y ) =
    let
        xpadding =
            100.0

        ypadding =
            100.0

        xinc =
            (pitchX - 2 * xpadding) / 4

        yinc =
            (pitchY - 2 * ypadding) / 6
    in
    ( xpadding + toFloat x * xinc, ypadding + toFloat y * yinc )


playerGoodPositionOpacity : String
playerGoodPositionOpacity =
    "0.5"


playerBadPositionOpacity : String
playerBadPositionOpacity =
    "0.1"


emptyPitchPosition : ( Int, Int ) -> Bool -> Svg.Svg Msg
emptyPitchPosition ( x, y ) positionSuitsPlayer =
    let
        ( xpos, ypos ) =
            pitchPosPixelPos ( x, y )

        opacity =
            if positionSuitsPlayer then
                playerGoodPositionOpacity

            else
                playerBadPositionOpacity
    in
    Svg.circle
        [ Svg.Events.onClick (MovePosition ( x, y ))
        , cx (String.fromFloat xpos)
        , cy (String.fromFloat ypos)
        , r <| String.fromFloat positionCircleRadius
        , fill "black"
        , fillOpacity opacity
        ]
        []


playerOnPitch : Team -> SquadViewState -> Int -> Int -> Int -> Svg.Svg Msg
playerOnPitch team squadViewState playerIdx x y =
    let
        maybePlayer =
            Array.get playerIdx team.players

        positionSuitsSelectedPlayer =
            case squadViewState.selectedPlayer of
                Nothing ->
                    False

                Just pidx ->
                    case Array.get pidx team.players of
                        Just player -> List.member (x, y) player.positions
                        _ -> False  -- should never happen. want Debug.crash

        label =
            case maybePlayer of
                Nothing ->
                    ( "Empty!", "red" )

                Just player ->
                    ( player.name
                    , if squadViewState.selectedPlayer == Just playerIdx then
                        "#8080ff"

                      else if List.member ( x, y ) player.positions && player.injury == 0 then
                        "white"

                      else
                        "#f77"
                    )

        opacity =
            if positionSuitsSelectedPlayer then
                playerGoodPositionOpacity

            else
                playerBadPositionOpacity

        {- case maybePlayer of
           Nothing -> playerBadPositionOpacity
           Just player ->
               -- players sitting on good positions get 'good position' opacity
               if Just playerIdx == squadViewState.selectedPlayer && List.member (x,y) player.positions then
                   playerGoodPositionOpacity
               else
                   playerBadPositionOpacity
        -}
        textAtPlayerPos : ( String, String ) -> Svg.Svg Msg
        textAtPlayerPos ( str, color ) =
            let
                ( xpos, ypos ) =
                    pitchPosPixelPos ( x, y )
            in
            Svg.g
                []
                [ Svg.circle
                    [ Svg.Events.onClick (SelectPlayer (Just playerIdx))
                    , cx (String.fromFloat xpos)
                    , cy (String.fromFloat ypos)
                    , r <|
                        String.fromFloat positionCircleRadius
                    , fill "black"
                    , fillOpacity opacity
                    ]
                    []
                , Svg.text_
                    [ Svg.Events.onClick (SelectPlayer (Just playerIdx))
                    , Svg.Attributes.textAnchor "middle"
                    , fill color
                    , Svg.Attributes.x (String.fromFloat xpos)
                    , Svg.Attributes.y (String.fromFloat ypos)
                    , Svg.Attributes.fontSize "26"
                    ]
                    [ Svg.tspan [ Svg.Attributes.x <| String.fromFloat xpos, dy "-10" ] [ Svg.text <| String.fromInt (playerIdx + 1) ]
                    , Svg.tspan [ Svg.Attributes.x <| String.fromFloat xpos, dy "30" ] [ Svg.text str ]
                    ]
                ]
    in
    textAtPlayerPos label


update : Msg -> State -> ( State, Cmd RootMsg.Msg )
update msg state =
    case msg of
        ViewSquad ->
            ( { state | view = SquadView { selectedPlayer = Nothing } }, Cmd.none )

        ViewPlayer player ->
            ( { state | view = PlayerView player }, Cmd.none )

        SellPlayer player ->
            ( state, ClientServer.sellPlayer player.id )

        SelectPlayer (Just p) ->
            let
                ( newState, changed ) =
                    applySelectPlayer state p
            in
            ( newState
            , if changed then
                ClientServer.saveFormation <| newState.team

              else
                Cmd.none
            )

        SelectPlayer Nothing ->
            ( { state | view = SquadView { selectedPlayer = Nothing } }, Cmd.none )

        -- move selected player to new position
        MovePosition pos ->
            case state.view of
                SquadView squadView ->
                    case squadView.selectedPlayer of
                        Nothing ->
                            ( state, Cmd.none )

                        Just playerIdx ->
                            let
                                newTeam =
                                    movePlayerPosition state.team playerIdx pos
                            in
                            if newTeam /= state.team then
                                ( { state
                                    | team = newTeam
                                    , view = SquadView { selectedPlayer = Nothing }
                                  }
                                , ClientServer.saveFormation <| newTeam
                                )

                            else
                                ( { state | view = SquadView { selectedPlayer = Nothing } }, Cmd.none )

                _ ->
                    ( state, Cmd.none )


movePlayerPosition : Team -> Int -> ( Int, Int ) -> Team
movePlayerPosition team playerIdx pos =
    -- can't move the goalkeeper!
    if playerIdx == 0 then
        team

    else
        { team | formation = Array.set playerIdx pos team.formation }


applySelectPlayer : State -> Int -> ( State, Bool )
applySelectPlayer state p =
    case state.view of
        SquadView squadView ->
            case squadView.selectedPlayer of
                Nothing ->
                    ( { state | view = SquadView { selectedPlayer = Just p } }, False )

                Just q ->
                    if p == q then
                        ( { state | view = SquadView { selectedPlayer = Nothing } }, False )

                    else
                        ( { state
                            | view = SquadView { selectedPlayer = Nothing }
                            , team = swapPlayerPositions state.team p q
                          }
                        , True
                        )

        _ ->
            ( state, False )

swapPlayerPositions : Team -> Int -> Int -> Team
swapPlayerPositions team p q =
    let
        p1 = Array.get p team.players
        p2 = Array.get q team.players
    in
        case (p1, p2) of
            (Just player1, Just player2) ->
                { team | players = Array.set q player1 (Array.set p player2 team.players) }
            _ -> -- should never happen. would prefer to Debug.crash but it no longer exists...
                team
