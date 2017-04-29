# After Waltz

**AfterWaltz** is simply a tool for the dandy typesetter. With AfterWaltz, you could waltz your raws for AE typesetting, right from the convenience (?) of Aegisub. Byt being dandy as you are, you must impress some ladies. Oh, it happens that you're on a dancing competition with someone who might be dandier than you are. You must prove that you are the dandiest dandy, and make all the ladies go head over heels for you.

* **Waltz** is a dance for getting your dandy raws straight to AE. and impress all the ladies, of course. [DEVEL]
* **Tango** is a dance for preparing a that dandy AviSynth for the encode you must do. [PLANNED]
* **Polka** is a dance for setting the mood and getting a lady or two to faint. [DEVEL]

So, what it's gonna be and how are you going to dance? Let's find out NOW.

## Compatability
This plugin has been tested on the latest [Aegisub builds](http://plorkyeran.com/Aegisub/). However, the regular version of Aegisub 3.2.2 does not support it.

## How does it work?
Changes registry, makes a script file, calles VDub's CLI with it, fire up the script, ..., profit. Yeah, it does lots of dark magic under it's hood (probably unneccesary dark magic, since I'm a total noob when it comes to video editing). But it works. Kind of. I've been using it myself for our recent releases.

## How do I use it?
Simply enough. Time your typesets by frames *in Aegisub* (or get someone to do that for you. After all, you're dandy for a reason, right?), select all the timed lines* (each for every RAW) and go to Automation -> AfterWaltz. From there, choose your dance style and BE DANDY.
Your <s>ladies </s>files will be waiting for you wherever you told them  to be (by default, the origin video's folder).

 \* *if you're going to Polka, you do not have to choose any line. It's just a settings panel, really... though I can't tell what would happen if you do choose some lines.*

## Settings/Code toggles
*Since Polka hasn't been fully implemented as of yet, you can change the various settings **simply by editing the script**. Though these settings are kinda self-explanatory, I'm still going to be providing information here. Soon.*

## Compiling it yourself
You don't really have to (and I haven't tested if Aegisub supports compiled files, but it should on theory). But if you insist...

```
luac afterwaltz.lua -o aw.luac
```

## Dandy version history
### v0.1.01a
Minor modificiations I'll probably undo soon and changes to readme.md (this) file.
### v0.1a
Inital commit. AfterWaltz ready in Waltz mode, polka in devel.