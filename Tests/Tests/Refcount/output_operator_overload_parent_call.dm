// BYOND bug 2992664: Sound datums accumulate when routed through << override
// https://www.byond.com/forum/post/2992664
// Affected: BYOND 516 (516.1688 and earlier). Resolved by Lummox JR in 516.1689:
// "Overloads of the input and output operators caused the arguments to leak references"
// An operator<< overload that passes the output on with ..() leaked one reference to the
// right-hand value every time it was used.
/mob/output_listener/proc/operator<<(x)
	return ..()

/proc/RunTest()
	var/mob/output_listener/M = new
	var/sound/S = new
	var/datum/D = new

	M << S
	ASSERT(refcount(S) == 1)

	M << D
	M << D
	M << D
	ASSERT(refcount(D) == 1)
