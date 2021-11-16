state("EarthX") {
	long money : "mono-2.0-bdwgc.dll", 0x003A0C4C, 0x6C, 0xE74, 0x308, 0x10, 0x4, 0x3A8, 0x80;
}

startup
{
	vars.Log = (Action<object>)((output) => print("[EarthX ASL] " + output));

	settings.Add("smallRocketUnlocked", true, "Split when unlocking the small rocket");
	settings.Add("mediumRocketUnlocked", true, "Split when unlocking the medium rocket");
	settings.Add("cargoCapsuleUnlocked", true, "Split when unlocking the cargo capsule");
	settings.Add("largeRocketUnlocked", true, "Split when unlocking the large rocket");
	settings.Add("cargoSpaceshipUnlocked", true, "Split when unlocking the cargo spaceship");
	settings.Add("moonshipUnlocked", true, "Split when unlocking the Moonship");
	settings.Add("landedOnMoon", true, "Split when you're landed on the Moon");
	settings.Add("landedOnMars", true, "Split when you're landed on Mars");
	settings.Add("crewSpaceshipUnlocked", true, "Split when unlocking the crew spaceship");
	settings.Add("terraformedMars", true, "Split you've terraformed Mars");
	settings.Add("martiansOnMars", false, "Split when you've landed some martians");
}

init
{
	vars.CancelSource = new CancellationTokenSource();
	vars.ScanThread = new Thread(() =>
	{
		vars.Log("Starting scan thread.");

		Func<SigScanTarget, IntPtr> scanPages = (target) =>
		{
			IntPtr result = IntPtr.Zero;
			foreach (var page in game.MemoryPages())
			{
				var scanner = new SignatureScanner(game, page.BaseAddress, (int)(page.RegionSize));
				if ((result = scanner.Scan(target)) != IntPtr.Zero) break;
			}

			return result;
		};

		var aslDataTrg = new SigScanTarget(2, "00 00 37 13 37 13 37 13 37 13");
		var aslData = IntPtr.Zero;

		var token = vars.CancelSource.Token;
		while (!token.IsCancellationRequested)
		{
			if ((aslData = scanPages(aslDataTrg)) != IntPtr.Zero)
			{
				vars.Data = new MemoryWatcherList
				{
					new MemoryWatcher<bool>(aslData + 0x08) { Name = "hasGameStarted" },
					new MemoryWatcher<bool>(aslData + 0x09) { Name = "smallRocketUnlocked" },
					new MemoryWatcher<bool>(aslData + 0xA) { Name = "mediumRocketUnlocked" },
					new MemoryWatcher<bool>(aslData + 0xB) { Name = "largeRocketUnlocked" },
					new MemoryWatcher<bool>(aslData + 0xC) { Name = "heavyRocketUnlocked" },
					new MemoryWatcher<bool>(aslData + 0xD) { Name = "superheavyRocketUnlocked" },
					new MemoryWatcher<bool>(aslData + 0xE) { Name = "cargoCapsuleUnlocked" },
					new MemoryWatcher<bool>(aslData + 0xF) { Name = "crewCapsuleUnlocked" },
					new MemoryWatcher<bool>(aslData + 0x10) { Name = "cargoSpaceshipUnlocked" },
					new MemoryWatcher<bool>(aslData + 0x11) { Name = "tankerSpaceshipUnlocked" },
					new MemoryWatcher<bool>(aslData + 0x12) { Name = "crewSpaceshipUnlocked" },
					new MemoryWatcher<bool>(aslData + 0x13) { Name = "moonshipUnlocked" },
					new MemoryWatcher<bool>(aslData + 0x14) { Name = "landedOnMoon" },
					new MemoryWatcher<bool>(aslData + 0x15) { Name = "landedOnMars" },
					new MemoryWatcher<bool>(aslData + 0x16) { Name = "martiansOnMars" },
					new MemoryWatcher<bool>(aslData + 0x17) { Name = "terraformedMars" }
				};

				vars.Log("Found AutoSplitterData.");
				break;
			}

			vars.Log("AutoSplitterData not yet found.");
			Thread.Sleep(2000);
		}

		vars.Log("Exiting scan thread.");
	});

	vars.ScanThread.Start();
	print("Your money is " + current.money);
}

update
{
	if (vars.ScanThread.IsAlive) return false;

	vars.Data.UpdateAll(game);
}

start
{
	if(old.money != current.money && current.money == 60000000){
		return true;
	}
}

split
{
    foreach (var watcher in vars.Data)
    {
        if (!watcher.Old && watcher.Current && settings[watcher.Name])
            return true;
    }
}


exit
{
	vars.CancelSource.Cancel();
}

shutdown
{
	vars.CancelSource.Cancel();
}