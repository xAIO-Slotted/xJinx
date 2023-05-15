A release of My and @ampx Jinx Lua
``` https://github.com/xAIO-Slotted/xJinx/blob/main/xJinx.lua ```
```https://github.com/xAIO-Slotted/xCore/blob/main/xCore.lua ```
```Instructions```
Add xJinx.lua to the lua folder
thats it :slight_smile:
----
```Prerequsesites:```
If you do not have the xJinx.lua will download them for you when you start it up the first time:
xCore.lua  ---> c:/slottedWeirdName/lua/lib folder
Corbel.ttf --->  c:/slottedWeirdName/fonts folder 
Roboto-Regular.ttf ---> c:/slottedWeirdName/fonts folder 

-- if you do not have the font files the script will create them put you will have to restart slotted after that

-- the script will also automatically keep itself up to date, it's opensource


[I expect this is buggy so please help me test / I'll take down if it's unusable but it's semi / okay tested]

```info```
Please dm me or @pingpongpow me in lua-chat/help with questions about how stuff works or 
DM me if crashes or bugs, I will see that faster

the debug/permashow/ and target selector are public and any dev can use thanks to ampX
https://i.gyazo.com/aeaedbb9b749ccc5ef28f6d7d1cad780.mp4
Features-
```
Q:
---- Q AOE splash Farm x minions slider with mana slider and fast clear mode
---- Q Combo AOE logic
---- Q Cs minions out of range that will die without rockets(spellfarm)
---- Q Extend Auto attack range by attacking splashable minions (plus visuals)
W:
---- W on Dash / chain CC / Channel / Zhonyas (unless needs to evade, or agc is too close or under enemy tower)
---- W Harass outside auto range
---- W combo logic (only if can weave between outattacks, raises dps accounts for variable w cast time with attack speed)
---- W Force W semi manual while in FULL_COMBO (holding control)
---- W KS
E:
---- E Dash/Zhonyas/Chain CC/Channel (see W logic exceptions)
---- E Combo multi hit -> e if it will hit target and atleast one other
---- E Combo On target if slowed
--- (needs more logic)
R:
---- R KS (littllllle bit wonky sorry, fix coming soon)
---- R Semi manual ulti, hold U (maybe ill make it customizable idk)
---- R  -- -- option: dont use if enemy has a dash
---- R MultiHit Combo for damage (if will hit 3 <65% hps and allys can follow up)
--- R Baseult to recall spot if spotted on vision (even if lose vision)
--- R base ult (only if it cannot hit Recall position)
```

damage visualizer
https://i.gyazo.com/2ad6840dbcdce81dffb02179eaac1448.mp4
Show R damage in R (if not on CD)
Shows zap damage on blue (if not on CD)
shows 3/4 auto attacks in purple (depending on attacks speed)
Text guide on spell usage plus auto to kill (in picture

PermaShow: 
display Current Q AOE farm status and extend Harass toggle (A and I keys)
Shows active status of fast W mode and Semi auto Utli (when keys held Control / U)
Moveable and clickable 
https://i.gyazo.com/92280596846556807abee0259493dede.png


Debug mode:
Will print current status on sceeen near the hud in white text, can let you know what the script is thinking
Has 3 modes on a slider can set debug to: off/info/debug/trace levels
 0: off 1: some messages 2: more message 3: all messages

xTargetSelector :
Currently the only reason why lua work
@ampx  could explain better but theoretically the best TargetSelector.
Uses tons of customizable weights
https://i.gyazo.com/23a4d377ecbc0f551109cdb27f2c7467.png

if I find time and desire I may convert into jetAIO as well
