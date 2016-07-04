module Comportment.Update exposing (..)

import Dict exposing (Dict)
import Comportment.Model as Model exposing (Model, BehaviorData)
import Status.Model exposing (ActiveState)

type Msg =
  SetBehavior BehaviorData
    | ReviveAll ActiveState

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    revive behavior =
       {behavior | overwhelmed = False}
    insert dict behavior =
      Dict.insert behavior.name behavior dict
    revive_all = 
      Dict.foldl (\name behavior dict -> revive behavior |> insert dict) Dict.empty model.behaviors 
  in
    case msg of
      ReviveAll activeState ->
        if activeState.active then
          ({model | behaviors = revive_all}, Cmd.none)
        else
          (model, Cmd.none)
      SetBehavior behaviorData ->
        let
          behavior = Dict.get behaviorData.name model.behaviors |> Maybe.withDefault (Model.defaultBehavior behaviorData.name)
          updatedBehavior =
            case behaviorData.event of
              "started" -> {behavior | started = True}
              "stopped" -> if behaviorData.reflex then
                             {behavior | started = False, reflex = True, state = "nothing"}
                           else
                               {behavior | started = False, reflex = False} 
              "overwhelmed" -> {behavior | started = True, overwhelmed = True}
              "inhibited" -> {behavior | started = True, inhibited = True}
              "transited" -> {behavior | started = True, overwhelmed = False, inhibited = False, reflex = behaviorData.reflex, state = behaviorData.value}
              _ -> behavior
        in
          ({model | behaviors = Dict.insert behavior.name updatedBehavior model.behaviors}, Cmd.none)

