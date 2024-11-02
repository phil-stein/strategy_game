# strategy game

xcom / mario kingdom rabbits inspired strategy game made using odin & opengl

plan ur turn seeing the enemies turn to interact with their moves

use combo moves to extend your playable chars abilities/moveset with the other player chars or enemies

## todo
  - ui
    - editor ui
      - [ ] port nuklear
    - game ui
      - [ ] text
        - [ ] port the text rendering code
        - [ ] instanced / batched rendering
  - gameplay
    - [ ] a* pathfinding `WIP`
    - [ ] player chars
      - [ ] move to pathfinding result
      - [ ] multiple player chars ( 3 probably )
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
  - graphics
    - game art
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
    - [ ] graphic effects
      - [ ] ambient occlusion
      - [ ] shadows
      - [ ] bloom
    - [ ] special stuff
      - [ ] water shader
      - [ ] leaves / bushes / vegetation
  - core
    - [ ] custom asset formats
      - [ ] texture
      - [ ] mesh
    - [ ] batched / instanced rendering
    - [ ] particle system
    - [ ] proper asset streaming / loading
