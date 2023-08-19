# UFO - Universal FlyOut

A World of Warcraft addon

UFO lets you create custom actionbar flyout menus similar to the built-in ones for mage portals, warlock demons, dragonriding abilities, etc.  But with UFO, you can include anything you want:

* Spells
* Items
* Mounts
* Pets
* Macros
* Trade skill Windows
* More? Let me know!

UFO adds a flyout catalog UI onto the side of various panels (Spellbook, Macros, Collections) to let you create and organize multiple flyouts.  These can be shared between all characters on your account.

From there, you can drag your flyouts onto your action bars.  Each toon keeps their own distinct record of which flyouts are on which bars.  Furthermore, placements are stored per spec and automatically change when you change your spec.

![UFO Catalog](../assets/assets/UFO-Catalog-Open.png)

![Flyouts](../assets/assets/Shared-Flyout.png)

![Demo](../assets/assets/ufo-cap-2-med-720-4fps.gif)

### 3rd-Party Addon Support

There is limited (let's call it beta) support for a few action bar and other addons:
* [Bartender4](https://www.curseforge.com/wow/addons/bartender4)
* [ElvUI](https://tukui.org/elvui)
* [LargerMacroIconSelection](https://www.curseforge.com/wow/addons/larger-macro-icon-selection)
* Want more? [[Make a request]](https://github.com/ScottIngram/Ufo/issues/new?labels=3rd+party+addon)

### FAQ:

**Q:** How do I open UFO?  
**A:** Any of the following will open the UFO Catalog where you can create and organize your custom flyouts:
* Type `/ufo`
* Click the [UFO] button in the upper right corner of the 
  * Spellbook
  * Collections Panel
  * Macros Panel
* Click "UFO" in the Addon Compartment (the new menu Blizzard added in Dragonflight to the upper right corner of the minimap).

**Q:** What if one toon places an ability / item / etc. only they can use onto a flyout shared with other toons?  
**A:** A flyout on the actionbars will only show buttons that are usable by the current toon.  However, in the catalog, all buttons will be visible.  

**Q:** Do I have to set up my flyouts on the action bars over and over for each spec?  
**A:** The first time you change to a different spec, UFO will copy  your current flyout positions to the new spec.  From that point, they are separate and must be changed independently.


### Acknowledgements

Many thanks to [Sébastien Desvignes](https://github.com/Boboseb) and his addon [FloFlyout](https://www.curseforge.com/wow/addons/floflyout) which was the basis for my work here.
