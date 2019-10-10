# sysprep.sh

Quick script for running initial actions on new Digital Ocean droplets. Salt states are great, but this is very, very simple.

Runs through the following setup steps:

* Timezone selection
* Root user configuration
* Standard user creation
* Python installation
* Swap file setup
* iptables configuration
* Common `apt` package installation
* Pillow dependency installation

Designed for Ubuntu 18.04 on a 1024MB RAM instance, but fairly portable.

## Usage

I know piping URLs to bash is evil. It's especially terrible to do it as root. Look at the file. Be sensible.

```
# bash <(curl -o - https://raw.githubusercontent.com/biggleszx/sysprep.sh/master/sysprep.sh)
```

## License

```
The MIT License (MIT)

Copyright (c) 2019 James Tiplady

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
