# Godot 4 interior mapping shader no cubemap
 Fake interior shader with use single texture for room

Port of this shader: https://forum.unity.com/threads/interior-mapping.424676/#post-2751518

Interior mapping shader which instead of cubemap, it uses texture atlas with room tiles that are front room view automatically mapped into a cube.
The alpha channel value - uniform for whole tile - is used to determine the rear wall's relative distance.

![image](https://user-images.githubusercontent.com/45795134/204140740-9174187f-5a18-4903-a8b3-0f3e2640e4b2.png)
