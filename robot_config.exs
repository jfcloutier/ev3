# Sensors and motors and ports
# Used when on the BrickPi because it can not discover automatically which devices are connected where

[%{port: :in1, device: :touch},
 %{port: :in2, device: :color},
 %{port: :in3, device: :infrared},
 %{port: :in4, device: :ultrasonic},
 %{port: :outA, device: :large}, # left
 %{port: :outB, device: :large}, #right
 %{port: :outC, device: :medium}]
