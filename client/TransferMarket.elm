module TransferMarket exposing (view, update)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)

import RootMsg
import Types exposing (..)
import TransferMarketTypes exposing (Msg, State, Msg(ViewListing, ViewAll, UpdateBidInput, MakeBid, WithdrawBid),
                                     View(ListView, PlayerView))
import PlayerDetailedView
import Styles

view : State -> Html Msg
view state = case state.view of
    PlayerView pvstate ->
        let bidInput = div [] [
                button [class "action", onClick MakeBid] [text "Make bid"],
                input [ type_ "number", step "10000", value <| toString pvstate.bidInputValue, onInput <| UpdateBidInput ] []
            ]
            withdrawButton = div [] [button [class "action", onClick WithdrawBid] [text "Withdraw bid"]]
        in
            div [] [
                h2 [] [text "Transfer Listing"],
                PlayerDetailedView.view pvstate.listing.player,
                div [class "half-width"] [
                    div [Styles.defaultMargin] [
                        case pvstate.listing.status of
                        ForSale -> div [] [
                            text <| "Accepting offers over £" ++ toString pvstate.listing.minPrice,
                            bidInput
                        ]
                        YouBid amount -> div [] [
                            text <| "Your current bid is £" ++ toString amount,
                            bidInput, withdrawButton]
                        YouWon -> div [] [text "You have signed this player."]
                        YouLost -> div [] [text "You were outbid by another team."]
                    ]
                ],
                button [class "nav", onClick ViewAll] [text "Back to listings"]
            ]

    ListView ->
        let
            listingToTr : TransferListing -> Html Msg
            listingToTr listing =
                Html.tr [onClick <| ViewListing listing] [
                    Html.td [] [text <| listing.player.name],
                    Html.td [] [text <| toString <| listing.minPrice],
                    Html.td [] [text <| case listing.status of
                        ForSale -> "For Sale"
                        YouBid amount -> "Your bid: " ++ toString amount
                        YouWon -> "You won!"
                        YouLost -> "You lost."
                    ],
                    Html.td [] [text <| toString <| listing.player.shooting],
                    Html.td [] [text <| toString <| listing.player.passing],
                    Html.td [] [text <| toString <| listing.player.tackling],
                    Html.td [] [text <| toString <| listing.player.handling],
                    Html.td [] [text <| toString <| listing.player.speed]
                ]
        in div [] [
          Html.h2 [] [text "Transfer Market"],
          Html.table [class "transfer-listings"] (
              (Html.tr [] [
                Html.th [] [text "Name"]
              , Html.th [] [text "Min Price"]
              , Html.th [] [text "Status"]
              , Html.th [] [text "Sh"]
              , Html.th [] [text "Pa"]
              , Html.th [] [text "Ta"]
              , Html.th [] [text "Ha"]
              , Html.th [] [text "Sp"]
              ]) ::
              (List.map listingToTr state.listings)
          )
        ]

makeBid : State -> Int -> TransferListing -> State
makeBid state amount listing =
    let updatedListing = { listing | status = YouBid amount }
        updatedListings = List.map (\l -> if l.id == listing.id then updatedListing else l) state.listings
    in { state | listings = updatedListings,
                 view = PlayerView { listing = updatedListing, bidInputValue = amount } }

withdrawBid : State -> TransferListing -> State
withdrawBid state listing =
    let updatedListing = { listing | status = ForSale }
        updatedListings = List.map (\l -> if l.id == listing.id then updatedListing else l) state.listings
    in { state | listings = updatedListings,
                 view = PlayerView { listing = updatedListing, bidInputValue = listing.minPrice } }

update : Msg -> State -> (State, Cmd RootMsg.Msg)
update msg state = case msg of
    WithdrawBid ->
        case state.view of
            PlayerView pvstate -> (withdrawBid state pvstate.listing, Cmd.none)
            _ -> (state, Cmd.none)
    MakeBid ->
        case state.view of
            PlayerView pvstate -> (makeBid state pvstate.bidInputValue pvstate.listing, Cmd.none)
            _ -> (state, Cmd.none)
    UpdateBidInput amount ->
        case state.view of
            PlayerView pvstate ->
                case String.toInt amount of
                    Ok amount -> ({ state | view = PlayerView { pvstate | bidInputValue = Basics.max pvstate.listing.minPrice amount } }, Cmd.none)
                    Err result -> ({ state | view = PlayerView pvstate }, Cmd.none)
            _ -> (state, Cmd.none)
        {-
        Ok amount -> (makeBid state amount pvstate, Cmd.none)
        Err result -> ({ state | view = PlayerView pvstate }, Cmd.none)
        -}
    ViewAll -> ({ state | view = ListView }, Cmd.none)
    ViewListing listing -> ({ state | view = PlayerView {listing=listing, bidInputValue=listing.minPrice}}, Cmd.none)
