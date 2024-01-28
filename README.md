# HaxeFlixel PONG

HaxeFlixel clone of PONG with multiplayer. Open [this link](https://t1ml3arn.github.io/HaxeFlixel-Pong/) to play in yor browser.

## Multiplayer

- Browser version supports WebRTC netplay. You will need 3rd party service to share connection data between players. Any chat will do (like Discord). Just follow in-game instrucions.
- Desktop version supports direct IP connection.

## Development

- install [Haxe 4.3.3](https://haxe.org/download/)
- (optionally) install [HashLink](https://hashlink.haxe.org/#download)
- clone the repo with `git clone https://github.com/T1mL3arn/HaxeFlixel-Pong.git`
- `cd` to the cloned repo
- create local haxelib dir for dependecies with `haxelib newrepo`
- install the dependecies with `haxelib install deps.hxml`
- try to compile and run html5

  ```
  lime test html5 -debug
  ```

  or HashLink

  ```
  lime test hl -debug
  ```

Debug builds (for desktop target) have fast connection mode for convenience - run the game instances with `pong.exe --server` and `pong.exe --client`.

## License

Code: WTFPL

Assets: The same as code unless stated otherwise, see assets folder
