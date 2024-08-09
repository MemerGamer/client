# Stat Scaling specification (v1)

This file explains the syntax for specifying scalings.
The current version has pretty strict rules so be sure to follow these instructions exactly, or the scalings won't initialize.

## General structure

The scalings are specified using a special formatted string.
The syntax is similar to what you would expect when inputting in a calculator.
At the moment this is very barebones and all these strict rules might be improved in future versions.
For now this is what you have to deal with.

Each argument ***MUST*** be separated by a space.
The first step is to split everything up in tokens and all parts are split by spaces.

The calculations are performend from left to right.
Multiplication is performend at the same priority as additions.
If you write something like `"1 + 2 * 3"` it will essentailly be interpreted as `"(1 + 2) * 3"`.

There is no support for brackets and using them will result in a parse error.

## Base value

Each scaling needs to start with a flat base value.
Without it the parsing will fail.
However on a technical level that is all that is needed for a scaling to be valid.
You can use it to simply return a fixed parameter.

## Operators

Currently the following operators are supported:

* `*`, `x`, `X` -> multiplication
* `/` -> division
* `+` -> addition
* `-` -> subtraction

As noted above the operators are always applied to the result of the previous calculations and the next operand.
If you have `"1 + 2 * 3 / 4 - 5 * 6"` it is essentially interpreted as `"((((1 + 2) * 3) / 4) - 5) * 6"`.
This is not what you might expect so be careful about the order of operations (or only use additions).

## Specifying operands

So far all that was touched is the base value and how operators work.
However a scaling specification is useless without a way to obtain values of the units.

First off at the moment only one fixed value is allowed: the base value.
All other operands must be scaled by some stat.

Each operand is split into two parts: The strength (a number) and a stat specifier.
These two get multiplier together and that result is then used as operand.
These two ***MUST*** be separated by a space.

The stat specifier specifies what stat should be retrieved for the calculation.
It has the following format: `actor.stat_set.stat_name`

### Possible actors

Every stat can be retreived from the following actors:

* `c`, `caster` -> The unit that caused the action that will be scaled
* `t`, `target` -> The unit that is target by this action. For AOE effects this will be done on a per unit basis.

### Possible stat sets

Every indivisual stat can be retreived from one of the following stat sets:

* `l`, `lvl`, `level` -> The level of the actor. Note: This doesn't need a stat_name after it.
* `m`, `max` -> The maximum stats of the actor. This stat set is rarely affected by temporary effects like buffs.
* `c`, `curr`, `current` -> The current stats of the actor. This is affected by basically everything happening with the unit.
* `b`, `base` -> The base stats of the unit. These are only changed by the level and nothing else.
* `miss`, `missing` -> The missing amount of the max stats. This is the result of max - curr.
* `bonus` -> The bonus stat amount. This is the amount that either max or curr are above the base stats.

### Possible stat names

As noted above if you want the level this isn't needed and will be ignore.

For every other stat set all the stats from the StatCollection and their abbrevation are available.
Check out that documentation page for more information.

## Examples

5% of the target maximum health:
`"0 + 0.05 t.max.hp"`

1% of the casters ability power multiplied by the attack crit chance:
`"0 + 0.01 c.current.ap * 0.01 c.curr.atk_crit"`

10 + 10% of the casters base movement speed
`"10 + 0.1 c.base.ms"`

One important thing to notice in these examples is how there is no operator between the scale strength and the stat specifier.
Another one is that even if it is 0, each scaling starts with a constant value.
While none of the example uses them, all valid operators are supported after the base value.
