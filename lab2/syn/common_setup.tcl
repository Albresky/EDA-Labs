set ADDITIONAL_SEARCH_PATH "/home/b16/lab2/cpu /home/b16/lab2/syn ./unmapped ./rtl ./scripts"
set TARGET_LIBRARY_FILES "/home/b16/lab2/syn/ref/typical_1v2c25.db /home/b16/lab2/syn/ref/SP013D3V1p2_typ.db"
set SYMBOL_LIBRARY_FILES "/home/b16/lab2/syn/ref/smic13g.sdb"

set search_path [list ./unmapped ./rtl ./scripts /home/b16/lab2/syn]
set target_library [list /home/b16/lab2/syn/ref/typical_1v2c25.db /home/b16/lab2/syn/ref/SP013D3_V1p2_typ.db]
set link_library "* $target_library"
set symbol_library [list /home/b16/lab2/syn/ref/smic13g.sdb]
