module Utils exposing (dateFormat, timeFormat, moneyFormat)

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
    (Date.minute d |> toString)

timeFormat : Time.Time -> String
timeFormat t = Date.fromTime t |> dateFormat

moneyFormat : Int -> String
moneyFormat m =
    -- wow, this is shit. what's wrong with me?
    let bits = List.reverse <| String.split "" (toString m)
        formatByParts l = 
            let len = List.length l
            in if len == 0 then ""
                else if len < 3 then
                    String.append ((formatByParts <| List.drop 3 l)) (String.join "" <| List.reverse <| List.take 3 l)
                else 
                    String.append ((formatByParts <| List.drop 3 l) ++ ",") (String.join "" <| List.reverse <| List.take 3 l)
    in "€" ++ formatByParts bits
