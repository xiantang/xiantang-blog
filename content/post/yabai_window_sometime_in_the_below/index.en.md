---
title: "Yabai Sometimes Puts Windows Below Other Windows"
date: 2024-07-01T23:08:16+08:00
author: "xiantang"
tags: ["yabai"]
description:
draft: false
---

# Yabai Sometimes Puts Windows Below Other Windows

I've been using yabai on my company's MacBook and noticed it sometimes places windows below others, a behavior not observed on my personal MacBook.

By running `yabai -m query --windows`, I discovered differences in window layouts between the two machines:

```json
[
    {
        "id": 140,
        "pid": 1087,
        "app": "iTerm2",
        "space": 2,
        "level": 0,
        "layer": "normal",
        "opacity": 1.0000,
        "split-type": "none",
        "split-child": "second_child"
    },
    {
        "id": 97,
        "pid": 1012,
        "app": "Discord",
        "space": 5,
        "level": -20,
        "layer": "below",
        "opacity": 1.0000,
        "split-type": "none",
        "split-child": "second_child"
    },
    {
        "id": 120,
        "pid": 1062,
        "app": "Mail",
        "space": 4,
        "level": -20,
        "layer": "below",
        "opacity": 1.0000,
        "split-type": "none",
        "split-child": "second_child"
    }
]
```

The windows should all be in the `normal` layer. This led me to find this issue: [Everything as Normal Layer #1912](https://github.com/koekeishiya/yabai/issues/1912).

The solution is to run `yabai -m rule --add app=".*" layer=normal` to set all windows to the `normal` layer in yabai v6.0.3.

Version comparison revealed that my company's MacBook is running yabai v6.0.3 while my personal MacBook is on v5.0.
