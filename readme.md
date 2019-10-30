# Snip

Add code snippets to your code directly from the web.

## Installation

### Bash

```bash
# download script and place it in your initialization file
curl --fail "https://raw.githubusercontent.com/whoan/snip/master/snip.sh" > snip.sh &&
  echo "[ -f \"$PWD/\"snip.sh ] && source \"$PWD/\"snip.sh" >> .bashrc
# start a new session to take changes
bash
```

## Usage

Just add `snip("$url")` anywhere in your code and the retrieved content will be placed after that line.

Yoy can write your *snip line* as a comment to avoid your linter complaining about syntax (it will work the same).

## Examples

### C++

Let's compile *main.cpp* prefixed with `snip`:

```bash
$ cat examples/main.cpp
```
```cpp
//snip("https://raw.githubusercontent.com/whoan/snip/master/examples/snippet.hpp")
int main() {
  say_hello();
  return 0;
}
```

```bash
$ snip g++ examples/main.cpp && ./a.out
> Hello World
```

### Bash

```bash
$ cat examples/main.sh
```
```bash
#snip("https://raw.githubusercontent.com/whoan/snip/master/examples/snippet.sh")
say_hello
```

```bash
$ snip bash examples/main.sh
> Hello World
```

### Python

```bash
$ cat examples/main.py
```
```python
#snip("https://raw.githubusercontent.com/whoan/snip/master/examples/snippet.py")
say_hello()
```

```bash
$ snip python examples/main.py
> Hello World
```

### Docker

```bash
$ cat examples/Dockerfile
```
```
FROM alpine
#snip("https://raw.githubusercontent.com/whoan/snip/master/examples/snippet.dockerfile")
CMD sh say_hello.sh
```

```bash
$ snip docker build -q -t snip-docker -f examples/Dockerfile . && docker run snip-docker
> Hello World
```

## TODO

- ~Add cache to avoid downloading same code over again~ (Thanks [@sapgan](https://github.com/sapgan))

## Final notes

I created this script to reuse code with ease. It is not production ready... unless you know what you are doing.

## License

[MIT](https://github.com/whoan/snip/blob/master/LICENSE)
