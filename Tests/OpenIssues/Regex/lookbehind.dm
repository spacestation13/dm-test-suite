// https://www.byond.com/forum/post/2987146

/proc/RunTest()
	var/regex/pattern = regex(@"(?<![a-zA-Z\u0430-\u044F\u0451\u0410-\u042F\u0401])\u0435\u0440\u043f")

	pattern.Find_char("\u0441\u0435\u0440\u043f")
	ASSERT(isnull(pattern.match))

	pattern.Find_char("s\u0435\u0440\u043f")
	ASSERT(isnull(pattern.match))