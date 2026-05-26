// https://www.byond.com/forum/post/2988110

/proc/RunTest()
	var/alist/a = alist("a" = null, "b" = null, "c" = null)
	a -= a

	ASSERT(length(a) == 0)

	var/list/b = list("a" = null, "b" = null, "c" = null)
	b -= b

	ASSERT(length(b) == 0)