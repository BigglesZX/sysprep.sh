# sysprep.sh

Quick script for running initial actions on new Digital Ocean droplets. Salt states are great, but this is very, very simple.

Runs through the following setup steps:

* Updating installed packages
* Timezone selection
* Root user configuration
* Standard user creation
* Python/`virtualenv` installation
* Swap file configuration (this is [officially discouraged](https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04) but included here for... legacy reasons?)
* `iptables` configuration
* Common `apt` package installation
* MySQL configuration
* Pillow (Python image library) dependency installation

Designed for Ubuntu 20.04 on a 1GB RAM instance, but fairly portable. You can find a legacy version for Ubuntu 18.04 on the `ubuntu18` branch.

## Usage

Piping the contents of third-party URLs to `bash` is, on the whole, extremely risky behaviour. It's also quite convenient. Please inspect the contents of the script to satisfy yourself that it's benign before attempting to run it. You can make BIG TROUBLE for yourself otherwise! If you're in any doubt, don't proceed. I'm just a guy on the Internet! For some extra peace of mind you may wish to download the script first, using `wget` or `curl`, before running it.

```
# bash <(curl -o - https://raw.githubusercontent.com/biggleszx/sysprep.sh/main/sysprep.sh)
```

If you want to use the legacy version (which is no longer maintained) for Ubuntu 18.04, it's this:

```
# bash <(curl -o - https://raw.githubusercontent.com/BigglesZX/sysprep.sh/ubuntu18/sysprep.sh)
```

## nginx SSL configuration

As of June 2022 the script generates a self-signed SSL certificate (prompting for the necessary details) and modifies the nginx configuration for the `default` virtual host to accept HTTPS requests, since without this any HTTPS request will be passed to the first virtual host that includes an SSL `server` block in its configuration. This change introduces some [snippets](https://github.com/BigglesZX/sysprep.sh/tree/main/snippets) that are copied from the repository to the server via `curl`. Per the warning above, you should inspect the contents of these snippets before running the script and ensure you're happy with the contents. The snippets and cert generation commands were sourced from a DigitalOcean [tutorial](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-18-04) on the subject.

## SSH root access

When the script completes and your standard user is set up, you'll probably want to remove root's ability to log in over SSH.

Open the file `/etc/ssh/sshd_config` and locate the line:

```
PermitRootLogin yes
```

Change it to:

```
PermitRootLogin no
```

Restart the `ssh` service (be warned: this will probably disconnect you if you're currently connected via SSH):

```shell
# service ssh restart
```

## License

```
The MIT License (MIT)

Copyright (c) 2022 James Tiplady

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
