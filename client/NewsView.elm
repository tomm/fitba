module NewsView exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class)
import Json.Encode
import Model exposing (..)
import RootMsg exposing (..)
import Uitk
import Utils


view : Model -> Html Msg
view model =
    let
        emptyMsg =
            [ div [ class "center" ] [ text "The papers have nothing to say" ] ]

        newsItem item =
            div [ class "inbox-message" ]
                [ div [ class "news-article-title" ] [ text item.title ]
                , div [ class "news-article-date" ] [ text <| Utils.dateFormat item.time ]
                , div [ class "news-article-body" ]
                    [ span [] [ text item.body ] ]
                ]

        todayNews =
            model.news
    in
    Uitk.view Nothing (text "Fitba News") <|
        case List.length todayNews of
            0 ->
                emptyMsg

            _ ->
                h3 [] [ text <| Utils.dateFormat model.currentTime ]
                    :: List.map newsItem todayNews
