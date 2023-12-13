# hook

A Godot 4.2 networked multiplayer template.

## How to use

### UPNP

UPNP is enabled on most home routers. You can use this toggle to host a game for any of your friends to join over the internet.

NOTE: When you launch for the first time, you need to allow Godot or the game artifact to connect to _PUBLIC_ networks, not just your local, if you want to host via UPNP

## Features

"hook" is an attempt to create a re-usable multiplayer template for Godot 4.2
The following things should work:

- Hosting, with server player, UPNP host optional, serverless supported
- Joining
- Clients recieve updates on other joiners
- Clients can produce a projectile which is replicated properly
- Scoreboard updates across clients, scoreboards populate

### Why

My earlier attempts at programming multiplayer used a confusing combination of `MultiplayerSpawner` and `MultiplayerSyncronizer` that resulted in bugs, particularly when attempting to create new nodes, like projectiles. Spawning and destroying entities became sources of uncertainty, and the `rpc()` annotations were inconsistent.

Furthermore, syncing game state like scores, playerlists and game timers became chaotic.

The docs at [Godot 4.2 High-level multiplayer](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) provide good information, but end up incomplete. For instance, they do not cover `MultiplayerSpawner` or the fact that they require to be run on the server-only, using `if multiplayer.is_server():` to prevent bugs.

### Note on Client Authoritative vs. Server Authoritative

You generally want multiplayer to be 100% server authoritative. The set up in this project is not. If you expect your users to act in bad faith, you will need to follow a pattern where user input is synced the server, which then is processed on the sever and puppets the player actions back to the client's world state. This is a fairly onerous model, but largely prevents hacking and manipulation of game state.

In this project, we allow the client to direct it's own movement and to call RPC functions to update state essentially at will. The server optionally validates those calls and emits signals back to the clients to keep everything in sync. It is a high trust model. The server is responsible for coordination of global game state like the players list and scores. To change this to a purely server authoritative model, see the tutorials below, paying attention to how to syncronize player input.

### Tips and Resources

I recommend these videos or tutorials:

- [Godot 4 multiplayer: spawn and sync your 3D characters](https://www.youtube.com/watch?v=AytWpymeVJw)
- [Godot 4 - Online Multiplayer FPS From Scratch](https://www.youtube.com/watch?v=n8D3vEx7NAE)
- [Battery Acid Dev - How to choose your multiplayer backend](https://www.youtube.com/watch?v=sT0UPlJ2cpc&t=1004s)
