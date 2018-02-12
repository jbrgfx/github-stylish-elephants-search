module Main exposing (main)

import ElmSeHub
import Html


main : Program Never ElmSeHub.Model ElmSeHub.Msg
main =
    Html.program
        { view = ElmSeHub.view
        , update = ElmSeHub.update
        , init = ElmSeHub.init
        , subscriptions = ElmSeHub.subscriptions
        }
