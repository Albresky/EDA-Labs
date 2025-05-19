template : default { # ring template for power ring creation
side : horizontal {
	layer : METAL7
	width : 0.200000
	spacing : minimum
	offset : 0
}
side : vertical {
	layer : METAL8
	width : 0.440000
	spacing : minimum
	offset : 0
}

  # Advanced rules for power plan creation
    advanced_rule : off { #all the advanced rules are turned off
	corner_bridge : off #connecting all rings at the corners
	align_std_cell_rail : off #align horizontal ring segments with std cell rails
	honor_advanced_via_rule : off # honor advanced via rules
    }
}
