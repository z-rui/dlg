# dlg

Dialog Generator for IUP

This is a replacement for out-dated LED that generates C code for an IUP dialog.

## Features

* Use interfaces such as `IupSetCallback`, `IupSetAttributeHandle` in place of deprecated `IupSetFunction`, etc.
* Do not assign a global name to generated IUP objects, use `NAME` attribute when applicable.
* Generate pure C code, without Lua dependency.

## Status

This project is currently under development.

The master branch now contains a (not so robust) working version.

## Build Guide

[LEMON Parser Generator](http://www.hwaci.com/sw/lemon/) and [re2c](http://re2c.org) are required to build **dlg** from source.

With the above installed, the building process is easy. Just type `make` in the command line.
