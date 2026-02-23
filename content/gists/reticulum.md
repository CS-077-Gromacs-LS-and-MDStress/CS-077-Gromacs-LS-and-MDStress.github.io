---
title: Reticulum QuickStart
author: Nathaniel Chappelle
date: Tue, 17 Feb 2026 16:00:00 -0800
---

This document serves as a guide to quickly accessing the reticulum network with
minimal configuration.

Start with this:

```sh
python3 -m venv .venv

source .venv/bin/activate

pip install rns nomadnet

# Adding peers to the RNS configuration
curl https://letsdecentralize.org/rollcall/reticulum.txt >> ~/.reticulum/config
```

Now you have the necessary network utils and RNS browser. Start `rnsd`, then in
another terminal window start `nomadnet`.

Read the introductory materials on that populate on the first launch of
`nomadnet`. Now you're ready to start exploring!

For example, you can navigate to the network tab and announce your local node,
or connect to another peer like
`3b5bc6888356193f1ac1bfb716c1beef:/page/index.mu`. Just hit `ctrl+u` and enter
that address (thanks [qbit](https://mammothcirc.us/@qbit)!)

It's seriously that simple. Decentralize yourself.
