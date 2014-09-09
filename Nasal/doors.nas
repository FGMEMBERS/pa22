######
#
# internal = 1 - inside view
# internal = 0 - outside view
#
######

var internal = 1;
setlistener("sim/current-view/view-number", func {
	internal = getprop("sim/current-view/internal");
}, 1);



######
#
# volume props
#
######

var volume = props.globals.getNode("sim/model/sound/volume", 1);
var wind_volume = props.globals.getNode("sim/model/sound/wind_volume", 1);



######
#
# Updating volume (engine, wind, flaps etc.) depending on opened/closed doors/windows/vents
#
######

var update_volume = func {

	var pilot_door = props.globals.getNode("sim/model/door-positions/pilot_door/position-norm");
	var passenger_door = props.globals.getNode("sim/model/door-positions/passenger_door/position-norm");
	var baggage_door = props.globals.getNode("sim/model/door-positions/baggage_door/position-norm");
	var pilot_window = props.globals.getNode("sim/model/door-positions/pilot_window/position-norm");
	var vent0 = props.globals.getNode("sim/model/door-positions/vent[0]/position-norm");
	var vent1 = props.globals.getNode("sim/model/door-positions/vent[1]/position-norm");
	var vent2 = props.globals.getNode("sim/model/door-positions/vent[2]/position-norm");
	var vent3 = props.globals.getNode("sim/model/door-positions/vent[3]/position-norm");
	
	var noise =0;
	if(pilot_door.getValue() > 0.001)
		noise = noise + 0.6;
		
	if(passenger_door.getValue() > 0.001)
		noise = noise + 0.6;
		
	if(baggage_door.getValue() > 0.001)
		# noise = noise + 0.01;
		noise = noise + 0.2;
		
	if(pilot_window.getValue() > 0.001)
		noise = noise + 0.5;
		
	if(vent0.getValue() > 0.001)
		# noise = noise + 0.4;
		noise = noise + 0.4;
		
	if(vent1.getValue() > 0.001)
		noise = noise + 0.3;
		
	if(vent2.getValue() > 0.001)
	    # noise = noise + 0.3;
		noise = noise + 0.2;
		
	if(vent3.getValue() > 0.001)
	    # noise = noise + 0.1;
		noise = noise + 0.2;
	
	volume.setDoubleValue(6 - (4 - 3 * noise) * internal - noise);
	
	if(noise > 0.001)
	    # wind_volume.setDoubleValue((6 - (3 - 3 * noise)) * internal);
		wind_volume.setDoubleValue((3 - (3 - 3 * noise)) * internal);
	else
		# wind_volume.setDoubleValue(0.5);
		wind_volume.setDoubleValue(0.0);
}



######
#
# Handle doors - opening, closing, selecting
#
######

var Doors = {
	new: func {
		var m = { parents: [Doors] };
		m.active = 0;
		m.list = [];
			
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/pilot_door"), 1.5) );
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/passenger_door"), 1.5) );
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/baggage_door"), 1.5) );
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/pilot_window"), 0.7) );
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/vent[0]"), 0.3) );
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/vent[1]"), 0.3) );
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/vent[2]"), 0.3) );
		append(m.list, aircraft.door.new( props.globals.getNode("sim/model/door-positions/vent[3]"), 0.3) );
			
		return m;
	},
	next: func {
		me.select(me.active + 1);
	},
	previous: func {
		me.select(me.active - 1);
	},
	select: func(which) {
		me.active = which;
		if (me.active < 0)
			me.active = size(me.list) - 1;
		elsif (me.active >= size(me.list))
			me.active = 0;
		gui.popupTip("Selecting " ~ me.list[me.active].node.getNode("name").getValue());
	},
	toggle: func {
		me.list[me.active].toggle();
	},
	reset: func {
		foreach (var d; me.list)
			d.setpos(0);
	},
};



######
#
# Doors main loop
#
######

var doors_loop = func {
	update_volume();
	settimer(doors_loop, 0);
}

var doors = Doors.new();

var pilot_door = doors.list[0];
var passenger_door = doors.list[1];
var baggage_door = doors.list[2];
var pilot_window = doors.list[3];
var vent0 = doors.list[4];
var vent1 = doors.list[5];
var vent2 = doors.list[6];
var vent3 = doors.list[7];

print("Nasal Doors System Initialized");

doors_loop();
