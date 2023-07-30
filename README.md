# SSH Tunnels

Let me share about **SSH Tunnels: Local and Remote port forwarding** 😋.

Table of contents

* [Prerequisites](#prerequisites)
* [Local Port forwarding](#local-port-forwarding)
* [Remote Port forwarding](#remote-port-forwarding)

<br></br>

## Prerequisites

Prepare the following environment.

* Local machine: Local PC
* Remote machine: Docker container 

Build and run container as Remote machine.

```
docker buildx build -t remote:latest .
```

```
docker run -d --rm --name remote -e PORT=80 -v $HOME/.ssh:/tmp/ssh remote:latest
```

Define the ip address of container as `REMOTE_IP`.

```
REMOTE_IP=$(
  docker inspect \
    -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  remote
)
```

Check if ssh connection can be established between local machine and remote machine by running the following command on Local machine.

```
ssh root@$REMOTE_IP
```

<br></br>

## Local port forwarding

The traffic encryped by ssh protcol to the port of the local machine can be forwarded to the port of the remote machine over the ssh tunnel securely.

For example, the web server on the remote machine can be accessible from the local machine by the local port forwarding.

We can see the following state after setting the above prerequisites.

<div align="center">
<img src="./images/ssh1.svg">
<p>Fig.</p>
</div>

The web server which listens on `localhost:80` is on the remote machine. It can be accessible in the remote machine, but ofcourse can't be accessible from the local machine.

For forwarding the local port, run the following command on the local machine.

```
ssh -L localhost:8080:localhost:80 root@$REMOTE_IP
```

This command means that the traffic to `localhost:8080` on the local machine is forwarded to `localhost:80` on the remote machine.

* `-L`: specifies that connections to the given TCP port on the local host are to be forwarded to the given host and port on the remote side.
* `localhost:8080:localhost:80` = (`local address:remote address`)
  * local address tells ssh client where to start listening.
  * remote address tells sshd server where to forward traffic to.

<div align="center">
<img src="./images/ssh2.svg">
<p>Fig. Localhost port forwarding.</p>
</div>

We can access `localhost:8080` on the local machine which's forwarded to the `localhost:80` on the remote machine by running `curl localhost:8080` on the local machine.

Running the following `ss` command proves that the ssh client listens on `localhost:8080`.

```
$ ss -nlp | grep 8080
tcp   LISTEN 0    128    127.0.0.1:8080  0.0.0.0:*    users:(("ssh",pid=368307,fd=5))                                 
tcp   LISTEN 0    128    [::1]:8080      [::]:*       users:(("ssh",pid=368307,fd=4))  
```

Not only the port of the loopback address(`localhost`) but also the port of the IP addresses on the other interfaces on the local machine can be forwarded as shown below.

```
ssh -L 192.168.11.2:8080:localhost:80 root@$REMOTE_IP
```

<div align="center">
<img src="./images/ssh3.svg">
<p>Fig. Localhost port forwarding 2.</p>
</div>

<br></br>

-----------------------

**Background:**

Use `ssh -f -N -L` to run the port-forwarding session in the background.

* `-f`: Requests ssh to go to background just before command execution.
* `-N`: Do not execute a remote command.  This is useful for just forwarding ports.

-----------------------

<br></br>

## Remote port forwarding

The traffic encryped by ssh protcol to the port of the remote machine can be forwarded to the port of the local machine over the ssh tunnel securely.

For example, the web server on the local machine can be accessible from the remote machine by the local port forwarding.

We prepare the web server which listens on `localhost:80` on the local machine by running the following command on the local machine.

```
sudo python3 -m http.server --bind 127.0.0.1 80 &
```

<div align="center">
<img src="./images/ssh4.svg">
<p>Fig.</p>
</div>

The web server which listens on `localhost:80` is on the local machine. It can be accessible in the local machine, but ofcourse can't be accessible from the remote machine.

For forwarding the remote port, run the following command on the local machine.

```
ssh -R localhost:8080:localhost:80 root@$REMOTE_IP
```

This command means that the traffic to `localhost:80` on the remote machine is forwarded to `localhost:8080` on the local machine.

* `-R`: Specifies that connections to the given TCP port on the remote host are to be forwarded to the local side.
* `localhost:8080:localhost:80` = (`remote address:local address`)
  * remote address tells sshd server where to start listening.
  * local address tells ssh client where to forward traffic to.

<div align="center">
<img src="./images/ssh5.svg">
<p>Fig. Remote port forwarding.</p>
</div>

We can access `localhost:8080` on the remote machine which's forwarded to the `localhost:80` on the local machine by running `curl localhost:8080` on the remote machine.

Not only the port of the loopback address(`localhost`) but also the port of the IP addresses on the other interfaces on the remote machine can be forwarded as shown below.

```
ssh -R $REMOTE_IP:8080:localhost:80 root@$REMOTE_IP
```

<div align="center">
<img src="./images/ssh6.svg">
<p>Fig. Remote port forwarding 2.</p>
</div>

To forward the port of the non-loopback address like the `$REMOTE_IP`, we need to set `GatewayPorts yes` in `/etc/ssh/sshd_config` in the remote machine. If not so, the port of the loopback address can be automatically forwarded.

<br></br>

-----------------------

**GatewayPorts (man sshd_config):**

By default, sshd(8) binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.

-----------------------

<br></br>

## _References_

* [A Visual Guide to SSH Tunnels: Local and Remote Port Forwarding](https://iximiuz.com/en/posts/ssh-tunnels/)

<br>

<div align="center">

**[`^        back to top        ^`](#ssh-tunnels)**

</div>