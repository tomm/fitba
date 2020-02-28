module Utils exposing (posixToSeconds, addSeconds, dateEq, dateFormat, dateTimeFormat, moneyFormat, onlyTimeFormat, timeFormat, timeFormatShort)

import Date
import DateFormat
import FormatNumber
import FormatNumber.Locales exposing (Locale, usLocale)
import Time exposing (Zone, Posix, utc)

addSeconds : Posix -> Int -> Posix
addSeconds t s = Time.millisToPosix (Time.posixToMillis t + 1000*s)

posixToSeconds : Posix -> Int
posixToSeconds p = Time.posixToMillis p // 1000

dateEq : Posix -> Posix -> Bool
dateEq ta tb =
    let a = Date.fromPosix utc ta
        b = Date.fromPosix utc tb
    in Date.year a
        == Date.year b
        && Date.month a
        == Date.month b
        && Date.day a
        == Date.day b


dateFormatter : Zone -> Posix -> String
dateFormatter =
    DateFormat.format
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text " "
        , DateFormat.dayOfMonthNumber
        , DateFormat.text " "
        , DateFormat.monthNameAbbreviated
        ]

dateFormat : Posix -> String
dateFormat d = dateFormatter utc d

dateTimeFormatter : Zone -> Posix -> String
dateTimeFormatter =
    DateFormat.format
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text " "
        , DateFormat.dayOfMonthNumber
        , DateFormat.text " "
        , DateFormat.monthNameAbbreviated
        , DateFormat.text " "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]

dateTimeFormat : Posix -> String
dateTimeFormat d = dateTimeFormatter utc d

timeFormatter : Zone -> Posix -> String
timeFormatter =
    DateFormat.format
        [ DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]


onlyTimeFormat : Time.Posix -> String
onlyTimeFormat t = timeFormatter utc t

timeFormat : Time.Posix -> String
timeFormat = dateTimeFormat


timeFormatterShort : Zone -> Posix -> String
timeFormatterShort =
    DateFormat.format
        [ DateFormat.dayOfWeekNameAbbreviated
        , DateFormat.text " "
        , DateFormat.hourMilitaryNumber
        , DateFormat.text ":"
        , DateFormat.minuteFixed
        ]

timeFormatShort : Time.Posix -> String
timeFormatShort t = timeFormatterShort utc t

moneyLocale : Locale
moneyLocale =
    { usLocale | decimals = 0 }


moneyFormat : Int -> String
moneyFormat m =
    "€" ++ (FormatNumber.format moneyLocale <| toFloat (m // 1000)) ++ "k"
