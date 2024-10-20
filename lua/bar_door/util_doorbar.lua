if CLIENT then

hook.Add("AddToolMenuCategories", "BaricadingDoorCategory", function()
    spawnmenu.AddToolCategory("Utilities", "Baricading Door", "Baricading Door")
end)

hook.Add("PopulateToolMenu", "BaricadingDoorSettings", function()
    spawnmenu.AddToolMenuOption("Utilities", "Baricading Door", "bardoorserver", "Barricading Door", "", "", function(panel)
        panel:ClearControls()
        panel:Help( "Baricading doors addon" )
        panel:CheckBox( "Players Support", "door_barricading_enable" )
        panel:ControlHelp( "On - Players will not be able to open barricaded doors" )
        panel:CheckBox( "NPCs Support", "door_barricading_npc" )
        panel:ControlHelp( "On - NPCs will not be able to open barricaded doors" )
        --
        panel:Help( "Values:" )
		panel:NumSlider( "Baricade Force Power", "door_barricading_forcepower", 0, 100000, 0 )
        panel:ControlHelp( "The force of throwing barricades away from the door" )
        panel:NumSlider( "Kick Door Chance", "door_barricading_kickchance", 0, 100, 0 )
        panel:ControlHelp( "Door kick chance from NPCs" )
    end)
end)

end