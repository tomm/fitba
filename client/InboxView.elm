module InboxView exposing (view)

import Html.Attributes exposing (class)
import Html.Events
import Html exposing (..)

import Model exposing (..)
import RootMsg exposing (..)
import Types exposing (..)
import Uitk
import Utils

view : Model -> Html Msg
view model =
    let emptyMsg = [div [class "center"] [text "Your inbox is empty"]]
        inboxItem msg = div [class "inbox-message"] [
            Uitk.row [
                Uitk.column 4 [
                    Uitk.crossButton (DeleteInboxMessage msg.id)
                ],
                Uitk.column 20 [
                    Uitk.row [
                        Uitk.column 12 [
                            div [class "inbox-message-from"] [text <| "From: " ++ msg.from ],
                            div [class "inbox-message-subject"] [text <| "Subject: " ++ msg.subject ]
                        ],
                        Uitk.column 12 [
                            div [class "inbox-message-date"] [text <| "Date: " ++ Utils.timeFormat msg.date]
                        ]
                    ],
                    div [class "inbox-message-body"] [text msg.body]
                ]
            ]
        ]
    in  Uitk.view Nothing "Inbox"
            <| case List.length(model.ourTeam.inbox) of
                0 -> emptyMsg
                _ -> List.map inboxItem model.ourTeam.inbox
