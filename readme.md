# Snip

Add code snippets to your code directly from the www.

## Installation

### Bash

```bash
# download script and place it in your initialization file
curl --fail "https://raw.githubusercontent.com/whoan/snip/master/snip.sh" > snip.sh && echo "[ -f \"$PWD/\"snip.sh ] && source \"$PWD/\"snip.sh" >> .bashrc
# start a new session to take changes
bash
```

## Examples

### C++

Let *file.cpp* have the content:

```cpp
snip("https://raw.githubusercontent.com/whoan/snip/master/example.hpp")

int main() {
  say_hello();
  return 0;
}
```

Prefix your compile line with `snip`:

```bash
$ snip g++ file.cpp
$ ./a.out
> Hello World
```

## TODO

- Add cache to avoid downloading same code over again
- Add namespaces to avoid eventual name collapsing

## Final notes

I created this script to reuse code with ease while I pracice coding or I need to have something running ASAP. It is not production ready... unless you know what you are doing.
