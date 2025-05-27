template : pg_mesh_top {
    layer : METAL8 {
        direction : horizontal
        width : 5
        spacing : 30
        number : 
        pitch : 41
        offset_start : boundary
        offset_type : edge
        offset : 
        trim_strap : true
    }

    layer : METAL7 {
        direction : vertical
        width : 5
        spacing : 30
        number : 
        pitch : 41
        offset_start : boundary
        offset_type : edge
        offset : 
        trim_strap : true
    }
    advanced_rule : off {

    }
}

template : pg_mesh_m2(p1, p2, p3, p4, p5) {
    layer : M2 {
        direction : vertical
        width : {@p1 @p2 @p3}
        spacing : {@p4 @p5}
        number :
        pitch : 16
        offset_start : boundary # user can also specify coordinate as {x y}
        offset_type : edge # user can also specify centerline
        offset :
        trim_strap : true
    }
    
    advanced_rule : on {
        stack_vias : all
        optimize_routing_tracks : off {
            layer : all
            alignment : true
            sizing : true
        }
        insert_channel_straps: off {
            layer :
            width : minimum
            spacing : minimum
            channel_threshold:
            check_one_layer : false
            boundary_strap : false
            honor_placement_blockage : true
            honor_voltage_area : false
            honor_keepout_margins : true
        }
        honor_max_stdcell_strap_distance : off {
            max_distance :
            layer :
            offset :
        }
        align_straps_with_power_switch : off {
            power_switch :
            layer :
            width :
            direction :
            offset :
        }
        align_straps_with_stdcell_rail: off {
            layer :
            align_with_rail : false
            put_strap_in_row : false
        }
        honor_advanced_via_rules : on
        align_straps_with_terminal_pin : off
        align_straps_with_physical_cell: off {
            layer :
            cell :
            pin :
            direction :
            width :
            offset :
        }
    }
}