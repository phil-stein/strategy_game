# strategy game

xcom / mario kingdom rabbits inspired strategy game made using odin & opengl

plan ur turn seeing the enemies turn to interact with their moves

use combo moves to extend your playable chars abilities/moveset with the other player chars or enemies

## todo
  * ui
    - [X] editor ui
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
        - [ ] batched rendering
  * gameplay
    - [X] a* pathfinding
      - [X] very basic pathfinding
      - [X] actual a*
      - [X] a* up / down slopes
        - [X] a* down ramps doesnt work yet
        - [X] cant go off one ramp onto another
          - because wp.level_idx is same, need to do floodfill or some to check for that case
            and then use game_a_star_pathfind_levels() multiple times
      - [ ] proper f-cost 
      - [X] doesnt always take the shortest route
        - i think happens when walking back route through closed_arr
      - [X] check having two ramps after one another
    - [X] player chars
      - [X] multiple player chars ( 3 probably )
      - [X] switch
      - [ ] ??? move to pathfinding result (actually play out result at end of turn)
    - [.] enemies
      - [X] stationary
      - [ ] ai
        - [X] simple
        - [ ] more advanced idk
      - [X] show their turn
    - [.] combo-moves
      - [X] basics
      - [X] jumping off other player chars
        - [X] curved line
      - [ ] tackle/kick/etc. enemies
      - [ ] carry enemies/player chars ?
      - [ ] push enemies/player chars ?
      - [ ] interact with environment
        - [ ] push buttons / pull levers / etc.
        - [X] bounce pads / trampolines
        - [ ] push blocks / obstacles
      - [ ] ...
      - [ ] show moves
        - better path drawing not using debug_draw
        - [ ] paths
        - [ ] curves
      - [X] limit the amount of moves chaned together in one turn
    - [ ] turns
    - [.] differrent tile types
      - [X] regular
      - [X] slopes
      - [ ] ladders / climable
      - [ ] ice
        - when on ice go straight until not on ice anymore ?
      - [ ] breakable
    - [X] mouse picking (id-buffer) 
      - [X] select between player_chars
      - [X] use mouse-picking when setting the path
  * graphics
    - [ ] vulkan or bgfx ?
    - [ ] __make renderer forward not defferred__
      - [ ] transparency
      - [ ] graphic effects
        - [ ] ambient occlusion
        - [ ] shadows
        - [ ] bloom
        - [ ] [subsurface scattering](https://www.youtube.com/watch?v=wfPoVnBFv-0)
      - [ ] special stuff
        - [X] current player-char outline
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
    - [X] proper debug_draw_update() proc drawing all registered debug-draws
    - [ ] make debug_draw_path/curve() also be abled to use gl.LINE_STRIP
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
    - [X] stack trace
      - [X] dump stack-trace ( core:debug/trace -> only works on assert not crash )
      - [X] try [dump stack trace](https://github.com/DaseinPhaos/pdb) ( doesnt work )
    - [X] factor out gameplay from main.odin 
    - [ ] hot-reloading
    - [ ] factor out code into packages 
      - [ ] assetm
      - [ ] data ? 
      - [ ] util
  * optimization
    - [ ] pass data using context or as proc args to avoid cache misses
    - [ ] make game_a_star_pathfind() use temp_allocator
    - [ ] find all allocations and check if context.temp_allocator could be used instead

## buggs
  - [X] debug_draw_mesh() rotates around center (0, 0, 0) not pos, see main.odin
  - [X] not freed in main.odin -> 231: data.player_chars[data.player_chars_current].path = make( [dynamic]waypoint_t, len(path), cap(path) )
  - [X] not freed in game.odin -> 514, 538, game_a_star_pathfind()  
  - [ ] booted up blank screen and infinite loop or some on laptop [23.12.24|00:50]
  - [ ] after sleep deprivation 
    - [ ] laptop no longer 160-220 fps now 15-30 fps, PS: dafuck did i do ??? 
      - [X] added text_draw_string() which is unbatched
      - [ ] ???
    - [ ] screen output buffer wrong size on startup -> prob. gl.Viewport()
    - [X] now just sometimes starts in fucking blank
     - [DEBUG] [assetm.odin:54:assetm_init()] [-]| framebuffer_t{type = "DEFERRED", buffer01 = 3, buffer02 = 4,
        buffer03 = 5, buffer04 = 6, fbo = 1, rbo = 1, size_divisor = 1, width = 1500, height = 1075}
       [DEBUG] [assetm.odin:56:assetm_init()] [\]| framebuffer_t{type = "RGB16F", buffer01 = 7, buffer02 = 0, b
       uffer03 = 0, buffer04 = 0, fbo = 2, rbo = 2, size_divisor = 1, width = 1500, height = 1075}
       [DEBUG] [assetm.odin:58:assetm_init()] [|]| framebuffer_t{type = "SINGLE_CHANNEL_F", buffer01 = 8, buffe
       r02 = 0, buffer03 = 0, buffer04 = 0, fbo = 3, rbo = 3, size_divisor = 1, width = 0, height = 0}
       [DEBUG] [assetm.odin:60:assetm_init()] [/]| framebuffer_t{type = "SINGLE_CHANNEL_F", buffer01 = 9, buffe
       r02 = 0, buffer03 = 0, buffer04 = 0, fbo = 4, rbo = 4, size_divisor = 4, width = 0, height = 0}
  - [ ] -sanitize:address buggy on laptop, f.e. in input.odin:input_key_callback()
        C:/Workspace/odin/03_games/xcom/src/input.odin(239:20) Index 4294967296 is out of range 0..<350
        =================================================================
        ==15112==ERROR: AddressSanitizer: array-bounds-exceeded on unknown address 0x7ffb95deb699 (pc 0x7ffb95de
        b699 bp 0x125b1f237780 sp 0x0054df4fc320 T0)
        ==15112==*** WARNING: Failed to initialize DbgHelp!              ***
        ==15112==*** Most likely this means that the app is already      ***
        ==15112==*** using DbgHelp, possibly with incompatible flags.    ***
        ==15112==*** Due to technical reasons, symbolization might crash ***
        ==15112==*** or produce wrong results.                           ***
            #0 0x7ffb95deb698 in RaiseException+0x68 (C:\WINDOWS\System32\KERNELBASE.dll+0x18003b698)
            #1 0x7ff660fe2aca in runtime.windows_trap_array_bounds-662 C:\#terminal_extensions\odin\base\runtime
        \procs_windows_amd64.odin:16
            #2 0x7ff660fe1bda in runtime.bounds_trap C:\#terminal_extensions\odin\base\runtime\error_checks.odin
        :6
            #3 0x7ff660ff13ab in runtime.bounds_check_error.handle_error-0 C:\#terminal_extensions\odin\base\run
        time\error_checks.odin:39
            #4 0x7ff660fe2bea in runtime.bounds_check_error C:\#terminal_extensions\odin\base\runtime\error_chec
        ks.odin:41
            #5 0x7ff6610472df in core.input_key_callback C:\Workspace\odin\03_games\xcom\src\input.odin:239     
            #6 0x7ff661175da0 in ImGui_ImplGlfw_KeyCallback+0xa0 (C:\Workspace\odin\03_games\xcom\bin\game.exe+0
        x1401c5da0)
            #7 0x7ff661156af5 in glfwGetWin32Window+0xc35 (C:\Workspace\odin\03_games\xcom\bin\game.exe+0x1401a6
        af5)
            #8 0x7ffb9725ef5b in CallWindowProcW+0x60b (C:\WINDOWS\System32\USER32.dll+0x18000ef5b)
            #9 0x7ffb9725e9dd in CallWindowProcW+0x8d (C:\WINDOWS\System32\USER32.dll+0x18000e9dd)
            #10 0x7ffb5b75f1ef in glPushClientAttrib+0x1508f (C:\WINDOWS\SYSTEM32\opengl32.dll+0x18003f1ef)     
            #11 0x7ffb9725ef5b in CallWindowProcW+0x60b (C:\WINDOWS\System32\USER32.dll+0x18000ef5b)
            #12 0x7ffb9725e9dd in CallWindowProcW+0x8d (C:\WINDOWS\System32\USER32.dll+0x18000e9dd)
            #13 0x7ff661175989 in ImGui_UpdatePlatformWindows+0x1b59 (C:\Workspace\odin\03_games\xcom\bin\game.e
        xe+0x1401c5989)
            #14 0x7ffb9725ef5b in CallWindowProcW+0x60b (C:\WINDOWS\System32\USER32.dll+0x18000ef5b)
            #15 0x7ffb9725e683 in DispatchMessageW+0x4a3 (C:\WINDOWS\System32\USER32.dll+0x18000e683)
            #16 0x7ff661153c27 in glfwPollEventsWin32+0x77 (C:\Workspace\odin\03_games\xcom\bin\game.exe+0x1401a
        3c27)
            #17 0x7ff66104b00b in core.main C:\Workspace\odin\03_games\xcom\src\main.odin:451
            #18 0x7ff660fe376e in main C:\#terminal_extensions\odin\base\runtime\entry_windows.odin:46
            #19 0x7ff6612a6cd3 in __scrt_common_main_seh D:\a01\_work\26\s\src\vctools\crt\vcstartup\src\startup
        \exe_common.inl:288
            #20 0x7ffb96b07373 in BaseThreadInitThunk+0x13 (C:\WINDOWS\System32\KERNEL32.DLL+0x180017373)       
            #21 0x7ffb9875cc90 in RtlUserThreadStart+0x20 (C:\WINDOWS\SYSTEM32\ntdll.dll+0x18004cc90)
        
        AddressSanitizer can not provide additional info.
        SUMMARY: AddressSanitizer: array-bounds-exceeded (C:\WINDOWS\System32\KERNELBASE.dll+0x18003b698) in Rai
        seException+0x68
        ==15112==ABORTING 


## naming-conventions
  - variables: snake_case
    - bools: has_XXX, is_XXX
    - ...
  - functions: snake_case
  - structs:   snake_case_t
  - constants: SCREAM_CASE
  - enums:     Camel_Snake_Case.SCREAM_CASE (XXX_Type, XXX_Flag) 
