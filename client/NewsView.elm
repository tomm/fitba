module NewsView exposing (view)

import Html.Attributes exposing (class)
import Html.Events
import Html exposing (..)
import Json.Encode
import Date

import Model exposing (..)
import RootMsg exposing (..)
import Types exposing (..)
import Uitk
import Utils

view : Model -> Html Msg
view model =
    let emptyMsg = [div [class "center"] [text "The papers have nothing to say"]]
        newsItem item = div [class "inbox-message"] [
            div [class "news-article-title"] [ text item.title ],
            div [class "news-article-date"] [text <| Utils.dateFormat <| Date.fromTime item.time],
            div [class "news-article-body"] [
                span [Html.Attributes.property "innerHTML" (Json.Encode.string item.body)] []
            ]
        ]
        todayNews = model.news
            --List.filter (\item -> Utils.dateEq (Date.fromTime model.currentTime) (Date.fromTime item.time)) model.news
    in  Uitk.view Nothing (text "Fitba News")
            <| case List.length(todayNews) of
                0 -> emptyMsg
                _ -> 
                    (h3 [] [text <| Utils.dateFormat <| Date.fromTime model.currentTime])
                    ::
                    (List.map newsItem todayNews)
