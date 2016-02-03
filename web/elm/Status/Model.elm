module Status.Model where

type alias ActiveState = {active: Bool}
                       
type alias RuntimeStats = {ramFree: Int, ramUsed: Int, swapFree: Int, swapUsed: Int}
                        
type alias Model = {paused : Bool,
                    active: Bool,
                    runtime : RuntimeStats
                   }

initialModel: Model
initialModel =
  Model False True {ramFree = -1, ramUsed = -1, swapFree = -1, swapUsed = -1}

