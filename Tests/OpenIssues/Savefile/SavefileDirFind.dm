// https://www.byond.com/forum/post/2986172

/proc/RunTest()
	fdel("test_save.sav")

	var/savefile/save = new("test_save.sav")

	save.cd = "/players/test/mobs/testckey"
	save["name"] << "Test Mob"

	save.cd = "/players/test/mobs/"

	var/list/characters = save.dir

	ASSERT(characters.Find("testckey") == 1)
	ASSERT("testckey" in characters)

	fdel("test_save.sav")