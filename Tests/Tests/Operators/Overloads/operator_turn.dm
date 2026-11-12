// BYOND bug 2992545: operator_turn doesn't do anything
// https://www.byond.com/forum/post/2992545
// Affected: BYOND 516 (516.1688 and earlier). Resolved by Lummox JR in 516.1689.
// turn() on a datum that defines operator_turn() threw "bad turn" instead of calling the overload.
/datum/rotator
	var/angle = 0

/datum/rotator/proc/operator_turn(deg)
	var/datum/rotator/R = new
	R.angle = angle + deg
	return R

/proc/RunTest()
	var/datum/rotator/R = new
	var/datum/rotator/turned = turn(R, 45)
	ASSERT(istype(turned, /datum/rotator))
	ASSERT(turned != R)
	ASSERT(turned.angle == 45)
	ASSERT(R.angle == 0)
