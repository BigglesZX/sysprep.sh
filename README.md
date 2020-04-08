# sysprep.sh

Quick script for running initial actions on new Digital Ocean droplets. Salt states are great, but this is very, very simple.

Runs through the following setup steps:

* Updating installed packages
* Timezone selection
* Root user configuration
* Standard user creation
* Python/virtualenv installation
* Swap file configuration
* iptables configuration
* Common `apt` package installation
* MySQL configuration
* Pillow (Python image library) dependency installation

Designed for Ubuntu 18.04 on a 512MB RAM instance, but fairly portable.

## Usage

Piping the contents of third-party URLs to `bash` is, on the whole, extremely risky behaviour. It's also quite convenient. Please inspect the contents of the script to satisfy yourself that it's benign before attempting to run it. You can make BIG TROUBLE for yourself otherwise! If you're in any doubt, don't proceed. I'm just a guy on the Internet! For some extra peace of mind you may wish to download the script first, using `wget` or `curl`, before running it.

```
# bash <(curl -o - https://raw.githubusercontent.com/biggleszx/sysprep.sh/master/sysprep.sh)
```

## License

```
The MIT License (MIT)

Copyright (c) 2020 James Tiplady

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
