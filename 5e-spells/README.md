# D&D stuff

Not so simple ruby scripts to handle information overload in D&D 5E revised and classic. Tightly coupled to the JSON format of data available on 5e.tools, this can give you all class and subclass features for any given combination, including filtering by levels. It can print some summaries of a character such that you know what variant rules are referenced by its class abilities, what abilities grant the use of a new bonus action or reaction or even if they relate to some conditions (such as imposing frightened).

As of right now it supports spells from Tasha's Cauldron of Everything, The revised PHB (known as XPHB), Xanathar's Guide to Everything and thats pretty much it. Like abilities, you can get the summary of a spellbook for a class or a character telling you what damage types are available and from which spells, what saves are targeted and for which spells as well as what condition and other specific rules are targed and for which spells. And you know which spells are bonus actions, reactions, use concentration and scale with higher levels.

It should be able to also print a text only version of the spellbook that can then be formatted appropriately

# Some classes and what they mean
TODO => move some or most of this into actual documentation

# Still To do
* move CharacterKlass, Subklass and KlassFeature parsing logic into some abstract layer
* lookup conditions in the condition list to have a printable cheat sheet
* maybe do the same thing with equipement at some point
* move some queries to the party level (right now scraper uses a dumb array of characterSheets)

# Random notes
The usage of `Klass` in names instead of `Class` is because we live in an object oriented world and `Class` is a keyword and I want to be unambiguous
