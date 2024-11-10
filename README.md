# strategy game

xcom / mario kingdom rabbits inspired strategy game made using odin & opengl

plan ur turn seeing the enemies turn to interact with their moves

use combo moves to extend your playable chars abilities/moveset with the other player chars or enemies

## todo
  * ui
    - editor ui
      - [x] port imgui 
      - [ ] entity explorer `WIP`
      - [ ] level editor
      - [ ] data window
    - game ui
      - [ ] text
        - [ ] port the text rendering code
        - [ ] instanced / batched rendering
  * gameplay
    - [ ] a* pathfinding `WIP`
      - [X] very basic pathfinding
      - [ ] actual a*
    - [ ] player chars
      - [ ] multiple player chars ( 3 probably )
      - [ ] switch
      - [ ] show moves `WIP`
      - [ ] move to pathfinding result
    - [ ] enemies
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
    - [ ] differrent tile types
      - [ ] regular
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
    - [ ] custom asset formats
      - [ ] texture
      - [ ] mesh
    - [ ] batched / instanced rendering
    - [ ] particle system
    - [ ] proper asset streaming / loading
  * game art
    - [ ] decide style
      - stylized pbr handpainted
        - normal + handpainted normals
        - normal + handpainted albedo
        - both
      - stylized pbr ( overwatch )
      - stylized pbr ( arcane inspired )
      - handpainted
    - [ ] export level as fbx/obj/etc.
    - [ ] make level art
    - [ ] make character art

## buggs
  - [x] debug_draw_mesh() rotates around center (0, 0, 0) not pos, see main.odin


## naming-conventions
  - variables: snake_case
    - bools: has_XXX, is_XXX
    - ...
  - functions: snake_case
  - structs:   snake_case_t
  - constants: SCREAM_CASE
  - enums:     Camel_Snake_Case.SCREAM_CASE (XXX_Type, XXX_Flag) 
