# tigerVR
A VR Library for Roblox

![preview gif lol](https://user-images.githubusercontent.com/45884377/200158531-582a1d6c-089f-44cf-8c3b-5dc16c5b14b2.gif)

## How to use in your game

Import the Script from [here](https://www.roblox.com/library/11480543122/tigerVR)

**OR**

Create a Script with the following code:

```lua
require(11480475962):create()
```

## How to use FBT?

1) [Have FullBody Trackers in SteamVR](https://www.vive.com/us/accessory/tracker3/)
2) Install the latest [tigerVR-client.exe](https://github.com/200Tigersbloxed/tigerVR/releases/latest/download/tigerVR-client.exe)
3) Launch SteamVR and turn on all of your trackers

> ___
> ⚠️ Warning! ⚠️
> 
> You can use only the following tracker combinations:
> + 1 Tracker : Chest
> + 2 Trackers : LeftFoot, RightFoot
> + 3 Trackers : Chest, LeftFoot, RightFoot
> ___

4) Run tigerVR-client.exe and follow the on-screen instructions

### Why is my FBT laggy?

This is a limitation by Roblox, as they do not allow WebSocket usage for "security" reasons [🙄](https://gist.github.com/200Tigersbloxed/5167a96893c47b2553feda552a96c536)

Please see [Line 15 in the NetworkingInterface](https://github.com/200Tigersbloxed/tigerVR/blob/main/tigerVR/Net/NetworkInterface.lua#L15) for more information.
