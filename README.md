> Extension of the multiplayer pong (https://github.com/godotengine/godot-demo-projects/tree/master/networking/multiplayer_pong) demo that covers the basics of high level networking in Godot Engine (3.1).

## Some features

* A main menu.
* A host/join menu with a lobby menu.
  * Players can connect to the server lobby
    * Number of players allowed per game is flexible via constant
  * Lobby ready feature
    * Number of ready players is flexiblee via constant
    * Start is available after players are readied

## Requirements

The updated repo requires the use of PR# (TBD).   This PR request implements new network capabilities; see the Updated Network Capabilities section.

## Updated Network Capabilities

* IP.get_local_addresses_full()
  * Returns an array of addresses (both v4 and v6) for each network adapter on the device.
* NetworkedMultiplayerEnet.get_host_address()
  * Returns the ip address of the server host.
* NetworkedMultiplayerEnet.get_host_port()
  * Returns the ip port of the server host.

## Open Source

[List of open source](opensource.md)

## License
Distributed under the terms of the MIT license, as described in the [LICENSE](LICENSE) file.
