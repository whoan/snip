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

## Examples

### C++

Let's compile *main.cpp* prefixed with `snip`:

```bash
$ cat examples/main.cpp
```
```cpp
snip("https://raw.githubusercontent.com/whoan/snip/master/snippet.hpp")

int main() {
  say_hello();
  return 0;
}
```

```bash
$ snip g++ examples/main.cpp
$ ./a.out
> Hello World
```

### Bash

```bash
$ cat examples/main.sh
```
```
#!/usr/bin/env bash

snip("https://raw.githubusercontent.com/whoan/snip/master/snippet.sh")

say_hello
```

```bash
$ snip bash examples/main.sh
> Hello World
```

## TODO

- Add cache to avoid downloading same code over again
- Add namespaces to avoid eventual name collapsing

## Final notes

I created this script to reuse code with ease. It is not production ready... unless you know what you are doing.

## License

[MIT](https://github.com/whoan/snip/blob/master/LICENSE)
