port module ElmSeHub exposing (..)

import Auth
import Color exposing (black, darkBlue, lightGrey, white)
import Element exposing (Element, alignBottom, alignLeft, centerY, column, height, image, layout, newTabLink, padding, paddingEach, paragraph, px, row, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import Element.Input as Input
import Html
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (..)
import String
import Table


responseDecoder : Decoder (List SearchResult)
responseDecoder =
    Json.Decode.at [ "items" ] (Json.Decode.list searchResultDecoder)


searchResultDecoder : Decoder SearchResult
searchResultDecoder =
    decode SearchResult
        |> required "id" Json.Decode.int
        |> required "full_name" Json.Decode.string


type alias Model =
    { query : String
    , results : List SearchResult
    , errorMessage : Maybe String
    , options : SearchOptions
    }


type alias SearchOptions =
    { searchIn : String
    }


type alias SearchResult =
    { id : Int
    , name : String
    }


initialModel : Model
initialModel =
    { query = "stylish-elephants"

    -- query = "style-elements"
    , results = []
    , errorMessage = Nothing
    , options =
        { searchIn = "name,description"
        }
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, githubSearch (getQueryString initialModel) )


subscriptions : Model -> Sub Msg
subscriptions _ =
    githubResponse decodeResponse


type Msg
    = Search
    | Options OptionsMsg
    | SetQuery String
    | HandleSearchResponse (List SearchResult)
    | HandleSearchError (Maybe String)
    | DoNothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Options optionsMsg ->
            ( { model | options = updateOptions optionsMsg model.options }, Cmd.none )

        Search ->
            ( model, githubSearch (getQueryString model) )

        SetQuery query ->
            ( { model | query = query }, Cmd.none )

        HandleSearchResponse results ->
            ( { model | results = results }, Cmd.none )

        HandleSearchError error ->
            ( { model | errorMessage = error }, Cmd.none )

        DoNothing ->
            ( model, Cmd.none )


updateOptions : OptionsMsg -> SearchOptions -> SearchOptions
updateOptions optionsMsg options =
    case optionsMsg of
        SetSearchIn searchIn ->
            { options | searchIn = searchIn }


view : Model -> Html.Html Msg
view model =
    Element.layout
        [ Background.color white
        , paddingLeft gutter
        ]
    <|
        column
            []
            [ header
            , row
                []
                [ paragraph
                    [ width (px 380)
                    , Element.spacing 10
                    , Background.color darkBlue
                    ]
                    (List.map viewSearchResult model.results)
                ]
            , note
            ]


header =
    paragraph [] [ text "Elm stylish-elephants github repositories" ]


note =
    paragraph [] [ text "'Elm lang' repos with 'stylish-elephants' in the name or description appear in the list." ]


viewErrorMessage : Maybe String -> Element Msg
viewErrorMessage errorMessage =
    case errorMessage of
        Just message ->
            text message

        Nothing ->
            text ""


viewSearchResult : SearchResult -> Element Msg
viewSearchResult result =
    newTabLink
        [ padding gutter
        , Background.color darkBlue
        , Font.color Color.white
        , Element.mouseOver [ Font.color Color.darkBlue, Background.color Color.orange ]
        , Font.bold
        , Font.size 18
        , Font.underline
        , alignBottom
        ]
        { url = "https://github.com/" ++ result.name
        , label = Element.text result.name
        }


gutter =
    10


paddingLeft n =
    paddingEach { right = 0, left = n, top = 0, bottom = 0 }


paddingTop n =
    paddingEach { right = 0, left = 0, top = n, bottom = 0 }


paddingBottom n =
    paddingEach { right = 0, left = 0, top = 0, bottom = n }


type OptionsMsg
    = SetSearchIn String



-- | SetUserFilter String


decodeGithubResponse : Json.Decode.Value -> Msg
decodeGithubResponse value =
    case Json.Decode.decodeValue responseDecoder value of
        Ok results ->
            HandleSearchResponse results

        Err err ->
            HandleSearchError (Just err)


decodeResponse : Json.Decode.Value -> Msg
decodeResponse json =
    case Json.Decode.decodeValue responseDecoder json of
        Err err ->
            HandleSearchError (Just err)

        Ok results ->
            HandleSearchResponse results



{-
   the app uses JS from github for search and reposnse
-}


port githubSearch : String -> Cmd msg


port githubResponse : (Json.Decode.Value -> msg) -> Sub msg


getQueryString : Model -> String
getQueryString model =
    -- See https://developer.github.com/v3/search/#example for how to customize!
    "access_token="
        ++ Auth.token
        ++ "&q="
        ++ model.query
        ++ "+in:"
        ++ model.options.searchIn
        ++ "+language:elm"
