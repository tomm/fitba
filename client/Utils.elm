module Utils exposing (dateFormat, timeFormat, moneyFormat, timeFormatShort)

import Time
import Date
import String
import List

dateFormat : Date.Date -> String
dateFormat d =
    (Date.dayOfWeek d |> toString)
    ++ " " ++
    (Date.day d |> toString)
    ++ " " ++
    (Date.month d |> toString)
    ++ " " ++
    (Date.hour d |> toString)
    ++ ":" ++
    (if Date.minute d < 10 then "0" else "") ++
    (Date.minute d |> toString)


timeFormat : Time.Time -> String
timeFormat t = Date.fromTime t |> dateFormat

timeFormatShort : Time.Time -> String
timeFormatShort t =
    let dateFormatShort d =
            (Date.hour d |> toString)
            ++ ":" ++
            (if Date.minute d < 10 then "0" else "") ++
            (Date.minute d |> toString)
    in Date.fromTime t |> dateFormatShort

moneyFormat : Int -> String
moneyFormat m =
    -- wow, this is shit. what's wrong with me?
    let bits num = List.reverse <| String.split "" (toString num)
        formatByParts l = 
            let len = List.length l
            in if len == 0 then ""
                else if len < 3 then
                    String.append ((formatByParts <| List.drop 3 l)) (String.join "" <| List.reverse <| List.take 3 l)
                else 
                    String.append ((formatByParts <| List.drop 3 l) ++ ",") (String.join "" <| List.reverse <| List.take 3 l)
    in
        if m >= 1000 then
            "€" ++ formatByParts (bits (m // 1000)) ++ "k"


        else
            "€" ++ formatByParts (bits m)
