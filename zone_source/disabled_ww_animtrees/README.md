# Why these two files were moved out of zone_assets (2026-09-02)

`animtrees/zm_buried_basic.atr` and `animstatedefs/zm_buried_basic.asd` are the
wonder-weapons work's MODIFIED copies (28/59 thundergun/tesla anim references).
They had been inert since mod_wonderweapons.zone stopped declaring them - that
zone file documents shipping the modified basic animtrees as a measured
every-map-crash ("Server script compile error: animation ... not defined in
anim tree", four crashes).

The Borough survival restoration declares `rawfile,animtrees/zm_buried_basic.atr`
+ `.asd` again (mod_locations.zone), because the aitype scripts need the tree
under zstandard - but it needs the STOCK copies from so_zclassic_zm_buried.ff.
The Linker resolves a declared rawfile from the asset search path (zone_assets)
BEFORE any --load'ed fastfile, so while these modified copies sat in
zone_assets they - not stock - would have shipped. Moved here, the declaration
falls through to so_zclassic_zm_buried.ff (verify: the build log line must say
`(src: so_zclassic_zm_buried)`, not `(src: disk)`).

The other five maps' modified trees still sit in zone_assets, undeclared and
therefore inert, exactly as before.
