# strategy game

xcom / mario kingdom rabbits inspired strategy game made using odin & opengl

plan ur turn seeing the enemies turn to interact with their moves

use combo moves to extend your playable chars abilities/moveset with the other player chars or enemies

## todo
  * ui
    - editor ui
      - [X] port imgui 
      - [X] entity explorer
      - [X] level editor
      - [X] data window
      - [X] assem explorer 
      - [X] timers
      - [X] use [reflection](https://pkg.odin-lang.org/core/reflect/) to make ui
    - game ui
      - [ ] text
        - [ ] port the text rendering code
        - [ ] instanced / batched rendering
  * gameplay
    - [ ] a* pathfinding `WIP`
      - [X] very basic pathfinding
      - [ ] actual a*
    - [X] player chars
      - [X] multiple player chars ( 3 probably )
      - [X] switch
      - [ ] move to pathfinding result
    - [ ] enemies
      - [ ] stationary
      - [ ] ai
      - [ ] show their turn
    - [ ] turns
    - [ ] combo-moves
      - [ ] jumping off other player chars
      - [ ] tackle/kick/etc. enemies
      - [ ] carry enemies/player chars ?
      - [ ] push enemies/player chars ?
      - [ ] interact with environment
        - [ ] push buttons / pull levers / etc.
        - [ ] bounce pads / trampolines
        - [ ] push blocks / obstacles
      - [ ] ...
      - [ ] show moves
    - [ ] differrent tile types
      - [X] regular
      - [ ] slopes
      - [ ] ladders / climable
      - [ ] ice
      - [ ] breakable
  * graphics
    - [ ] transparency
    - [ ] graphic effects
      - [ ] ambient occlusion
      - [ ] shadows
      - [ ] bloom
    - [ ] special stuff
      - [ ] water shader
      - [ ] leaves / bushes / vegetation
  * core
    - [X] custom asset formats
      - [X] texture
      - [X] mesh
    - [ ] batched / instanced rendering
    - [ ] particle system
    - [ ] proper asset streaming / loading
    - [ ] serialization
      - [ ] map
      - [ ] chars position
      - [ ] enemy layout
    - [ ] different hdri for reflections and bg
  * game art
    - [ ] decide theme
      - fantasy
      - sci-fi
      - steampunk
      - dieselpunk
      - __solarpunk__
      - horror
      - __lovecraftian__
    - [ ] decide style
      - stylized pbr handpainted
        - normal + handpainted normals
        - normal + handpainted albedo
        - both
      - stylized pbr ( overwatch )
      - stylized pbr ( arcane inspired )
      - handpainted
      - [ ] collect ref images 
      - [ ] make pureref reference board
    - [ ] make level art
      - [ ] export level as fbx/obj/etc.
    - [ ] make character art
  * upkeep & organisation 
    - [ ] stack trace
      - [X] dump stack-trace ( core:debug/trace -> only works on assert not crash )
      - [X] try [dump stack trace](https://github.com/DaseinPhaos/pdb) ( doesnt work )
    - [ ] hot-reloading
    - [ ] factor out code into packages 
      - [ ] assetm
      - [ ] data ? 
      - [ ] util
  * optimization
    - [ ] pass data using context or as proc args to avoid cache misses

## buggs
  - [X] debug_draw_mesh() rotates around center (0, 0, 0) not pos, see main.odin
  - [ ] not freed in main.odin -> 231: data.player_chars[data.player_chars_current].path = make( [dynamic]waypoint_t, len(path), cap(path) )


## naming-conventions
  - variables: snake_case
    - bools: has_XXX, is_XXX
    - ...
  - functions: snake_case
  - structs:   snake_case_t
  - constants: SCREAM_CASE
  - enums:     Camel_Snake_Case.SCREAM_CASE (XXX_Type, XXX_Flag) 
