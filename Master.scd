//MIXING + CONTROLS

Ndef.ar(\mix, 3);
Ndef(\mix).play;

Ndef(\mix, {var robot1, robot2, robot3;
	robot1 = Mix(Ndef(\happybot2).ar);
	robot2 = Mix(Ndef(\angrybot).ar);
	robot3 = Mix(Ndef(\sadrobot1).ar);
	[robot2,robot1,robot3];
});