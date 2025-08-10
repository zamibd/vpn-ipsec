 # IPsec VPN Server on Docker 

 Docker image to run an IPsec VPN server, with IPsec/L2TP, Cisco IPsec and IKEv2.

Based on Alpine 3.21 or Debian 12 with [Libreswan](https://libreswan.org) (IPsec VPN software) and [xl2tpd](https://github.com/xelerance/xl2tpd) (L2TP daemon).

An IPsec VPN encrypts your network traffic, so that nobody between you and the VPN server can eavesdrop on your data as it travels via the Internet. This is especially useful when using unsecured networks, e.g. at coffee shops, airports or hotel rooms.
 

## Quick start

Use this command to set up an IPsec VPN server on Docker:

```
docker run \
    --name vpn-ipsec \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    imzami/vpn-ipsec
```

Your VPN login details will be randomly generated. See Retrieve VPN login details.

## Features

- Supports IKEv2 with strong and fast ciphers (e.g. AES-GCM)
- Generates VPN profiles to auto-configure iOS, macOS and Android devices
- Supports Windows, macOS, iOS, Android, Chrome OS and Linux as VPN clients
- Includes a helper script to manage IKEv2 users and certificates

## Install Docker

First, [install Docker](https://docs.docker.com/engine/install/) on your Linux server to run this image,
 you may need to restart the Docker container once with `docker restart vpn-ipsec`. This image does not support Docker for Windows.

## Download

Get the trusted build from the [Docker Hub registry](https://hub.docker.com/r/imzami/vpn-ipsec/):

```
docker pull imzami/vpn-ipsec
```
 

### Image comparison

Two pre-built images are available. The default Alpine-based image is only ~18 MB.

|                   | Alpine-based             | 
| ----------------- | ------------------------ |
| Image name        | imzami/vpn-ipsec  | 
| Compressed size   | ~ 18 MB                  |
| Base image        | Alpine Linux 3.21        | 
| Platforms         | amd64, arm64, arm/v7     |
| Libreswan version | 5.3                      | 
| IPsec/L2TP        | ✅                       | 
| Cisco IPsec       | ✅                       | 
| IKEv2             | ✅                       | 

<details>
<summary>
I want to use the older Libreswan version 4.
</summary>

It is generally recommended to use the latest [Libreswan](https://libreswan.org/) version 5, which is the default version in this project. However, if you want to use the older Libreswan version 4, you can build the Docker image from source code:

```
git clone https://github.com/zamibd/vpn-ipsec
cd vpn-ipsec
# Specify Libreswan version 4 
# To build Alpine-based image
docker build -t imzami/vpn-ipsec .

```
</details>

## How to use this image

### Environment variables

**Note:** All the variables to this image are optional, which means you don't have to type in any variable, and you can have an IPsec VPN server out of the box! To do that, create an empty `env` file using `touch vpn.env`, and skip to the next section.

This Docker image uses the following variables, that can be declared in an `env` file (see [example](vpn.env.example)):

```
VPN_IPSEC_PSK=your_ipsec_pre_shared_key
VPN_USER=your_vpn_username
VPN_PASSWORD=your_vpn_password
```

This will create a user account for VPN login, which can be used by your multiple devices[*](#important-notes). The IPsec PSK (pre-shared key) is specified by the `VPN_IPSEC_PSK` environment variable. The VPN username is defined in `VPN_USER`, and VPN password is specified by `VPN_PASSWORD`.

Additional VPN users are supported, and can be optionally declared in your `env` file like this. Usernames and passwords must be separated by spaces, and usernames cannot contain duplicates. All VPN users will share the same IPsec PSK.

```
VPN_ADDL_USERS=additional_username_1 additional_username_2
VPN_ADDL_PASSWORDS=additional_password_1 additional_password_2
```

**Note:** In your `env` file, DO NOT put `""` or `''` around values, or add space around `=`. DO NOT use these special characters within values: `\ " '`. A secure IPsec PSK should consist of at least 20 random characters.

**Note:** If you modify the `env` file after the Docker container is already created, you must remove and re-create the container for the changes to take effect.

### Additional environment variables

Advanced users can optionally specify a DNS name, client name and/or custom DNS servers.

<details>
<summary>
Learn how to specify a DNS name, client name and/or custom DNS servers.
</summary>

Advanced users can optionally specify a DNS name for the IKEv2 server address. The DNS name must be a fully qualified domain name (FQDN). Example:

```
VPN_DNS_NAME=vpn.example.com
```

You may specify a name for the first IKEv2 client. Use one word only, no special characters except `-` and `_`. The default is `vpnclient` if not specified.

```
VPN_CLIENT_NAME=your_client_name
```

By default, clients are set to use [Google Public DNS](https://developers.google.com/speed/public-dns/) when the VPN is active. You may specify custom DNS server(s) for all VPN modes. Example:

```
VPN_DNS_SRV1=1.1.1.1
VPN_DNS_SRV2=1.0.0.1
```



By default, no password is required when importing IKEv2 client configuration. You can choose to protect client config files using a random password.

```
VPN_PROTECT_CONFIG=yes
```

**Note:** The variables above have no effect for IKEv2 mode, if IKEv2 is already set up in the Docker container. In this case, you may remove IKEv2 and set it up again using custom options.
</details>

### Start the IPsec VPN server

Create a new Docker container from this image (replace `./vpn.env` with your own `env` file):

```
docker run \
    --name vpn-ipsec \
    --env-file ./vpn.env \
    --restart=always \
    -v ikev2-vpn-data:/etc/ipsec.d \
    -v /lib/modules:/lib/modules:ro \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -d --privileged \
    imzami/vpn-ipsec
```

In this command, we use the `-v` option of `docker run` to create a new [Docker volume](https://docs.docker.com/storage/volumes/) named `ikev2-vpn-data`, and mount it into `/etc/ipsec.d` in the container. IKEv2 related data such as certificates and keys will persist in the volume, and later when you need to re-create the Docker container, just specify the same volume again.

It is recommended to enable IKEv2 when using this image. However, if you prefer not to enable IKEv2 and use only the IPsec/L2TP and IPsec/XAuth ("Cisco IPsec") modes to connect to the VPN, remove the first `-v` option from the `docker run` command above.
 
### Retrieve VPN login details

If you did not specify an `env` file in the `docker run` command above, `VPN_USER` will default to `vpnuser` and both `VPN_IPSEC_PSK` and `VPN_PASSWORD` will be randomly generated. To retrieve them, view the container logs:

```
docker logs vpn-ipsec
```

Search for these lines in the output:

```
Connect to your new VPN with these details:

Server IP: your_vpn_server_ip
IPsec PSK: your_ipsec_pre_shared_key
Username: your_vpn_username
Password: your_vpn_password
```

The output will also include details for IKEv2 mode, if enabled.

(Optional) Backup the generated VPN login details (if any) to the current directory:

```
docker cp vpn-ipsec:/etc/ipsec.d/vpn-gen.env ./
``` 
Enjoy your very own VPN! :sparkles::tada::rocket::sparkles:
 

## Update Docker image

To update the Docker image and container, first [download](#download) the latest version:

```
docker pull imzami/vpn-ipsec
```

If the Docker image is already up to date, you should see:

```
Status: Image is up to date for imzami/vpn-ipsec:latest
```

Otherwise, it will download the latest version. To update your Docker container, first write down all your [VPN login details]. Then remove the Docker container with `docker rm -f vpn-ipsec`.

## Configure and use IKEv2 VPN

IKEv2 mode has improvements over IPsec/L2TP and IPsec/XAuth ("Cisco IPsec"), and does not require an IPsec PSK, username or password.

First, check container logs to view details for IKEv2:

```bash
docker logs vpn-ipsec
```

**Note:** If you cannot find IKEv2 details, IKEv2 may not be enabled in the container. Try updating the Docker image and container

During IKEv2 setup, an IKEv2 client (with default name `vpnclient`) is created, with its configuration exported to `/etc/ipsec.d` **inside the container**. To copy config file(s) to the Docker host:

```bash
# Check contents of /etc/ipsec.d in the container
docker exec -it vpn-ipsec ls -l /etc/ipsec.d
# Example: Copy a client config file from the container
# to the current directory on the Docker host
docker cp vpn-ipsec:/etc/ipsec.d/vpnclient.p12 ./
```



<details>
<summary>
Learn how to manage IKEv2 clients.
</summary>

You can manage IKEv2 clients using the helper script. See examples below. To customize client options, run the script without arguments.

```bash
# Add a new client (using default options)
docker exec -it vpn-ipsec ikev2.sh --addclient [client name]
# Export configuration for an existing client
docker exec -it vpn-ipsec ikev2.sh --exportclient [client name]
# List existing clients
docker exec -it vpn-ipsec ikev2.sh --listclients
# Show usage
docker exec -it vpn-ipsec ikev2.sh -h
```

**Note:** If you encounter error "executable file not found", replace `ikev2.sh` above with `/opt/src/ikev2.sh`.
</details>
<details>
<summary> 
<details>
<summary>
Remove IKEv2 and set it up again using custom options.
</summary>

In certain circumstances, you may need to remove IKEv2 and set it up again using custom options.

**Warning:** All IKEv2 configuration including certificates and keys will be **permanently deleted**. This **cannot be undone**!

**Option 1:** Remove IKEv2 and set it up again using the helper script.

Note that this will override variables you specified in the `env` file, such as `VPN_DNS_NAME` and `VPN_CLIENT_NAME`, and the container logs will no longer show up-to-date information for IKEv2.

```bash
# Remove IKEv2 and delete all IKEv2 configuration
docker exec -it vpn-ipsec ikev2.sh --removeikev2
# Set up IKEv2 again using custom options
docker exec -it vpn-ipsec ikev2.sh
```

**Option 2:** Remove `ikev2-vpn-data` and re-create the container.

1. Write down all your VPN login details.
1. Remove the Docker container: `docker rm -f vpn-ipsec`.
1. Remove the `ikev2-vpn-data` volume: `docker volume rm ikev2-vpn-data`.
1. Update your `env` file and add custom IKEv2 options such as `VPN_DNS_NAME` and `VPN_CLIENT_NAME`, then re-create the container. 
</details>
 
## Technical details

There are two services running: `Libreswan (pluto)` for the IPsec VPN, and `xl2tpd` for L2TP support.

The default IPsec configuration supports:

* IPsec/L2TP with PSK
* IKEv1 with PSK and XAuth ("Cisco IPsec")
* IKEv2

The ports that are exposed for this container to work are:

* 4500/udp and 500/udp for IPsec
 
