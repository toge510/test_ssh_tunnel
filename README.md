# Test SSH Tunnels

SSH Tunnels: Local and Remote Port Forwardingについて、説明する。

## Prerequisites

以下環境を構築する。

* Local machine: Local PC
* Remote machine: Docker container 

Build & Run container.

```
docker buildx build -t remote:latest .
```

```
docker run -d --rm --name remote -e PORT=80 -v $HOME/.ssh:/tmp/ssh remote:latest
```

Check if ssh connection can be established between the client(local) and the server(Container).

Docker containerをシェル変数：`REMOTE_IP`として定義します。

```
REMOTE_IP=$(
  docker inspect \
    -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' \
  remote
)
```

Client: Local PCから、Server: Docker containerにsshコマンドでアクセスできることを確認する。

```
ssh root@$REMOTE_IP
```

<br></br>

## Local Port forwarding

* SSHトンネルを経由して、リモートマシンとの間でセキュアに暗号化された通信が行われます。
* Local machineのローカルポートへのトラフィックを、Remote machineのリモートポートへ転送します。
* 例えば、Remote環境のweb serverへLocal machineからアクセスできるようにすることが可能です。

上記のPrrerequisitesの実行した場合、今の状態は以下である。

<div align="center">
<img src="./ssh1.svg">
</div>

* Remote machineには、Remote machine内のlocalhost:80からアクセスできるweb serverがある。もちろん、Local machineからはアクセスできない。
* Local machineからremote machineへはsshでアクセスできる。= 通信を暗号化する安全なssh tunnelを確立できる。

Local Port forwardingを実行するには、以下コマンドをLocal machine上で実行する必要がある。

```
ssh -L localhost:8080:localhost:80 root@$REMOTE_IP
```

このコマンドは、local machineのlocalhost:8080へのtrafficeをremote machineのlocalhost:80にforwardすることを意味する。

* `-L`: specifies that connections to the given TCP port on the local host are to be forwarded to the given host and port on the remote side.
* `localhost:8080:localhost:80` = (`local address:remote address`)
  * local address tells ssh client where to start listening.
  * remote address tells sshd server where to forward traffic to.

Local machineのlocalhost:8080にアクセス(`curl localhost:8080`)すると、Remote machineの`localhost:80`にアクセスできる。

<div align="center">
<img src="./ssh2.svg">
</div>

`ss`コマンドによって、ssh clientが、`localhost:8080`でLISTENしていることが確認できる。

```
$ ss -nlp | grep 8080
tcp   LISTEN 0    128    127.0.0.1:8080  0.0.0.0:*    users:(("ssh",pid=368307,fd=5))                                 
tcp   LISTEN 0    128    [::1]:8080      [::]:*       users:(("ssh",pid=368307,fd=4))  
```

Local Machineのloopback addressだけでなく、他のinterfaceのIP addressをport fowardingすることも可能である。

```
ssh -L 192.168.11.2:8080:localhost:80 root@$REMOTE_IP
```

<div align="center">
<img src="./ssh3.svg">
</div>

* -gオプションの説明

-----
Background
--

Use `ssh -f -N -L` to run the port-forwarding session in the background.

* `-f`: Requests ssh to go to background just before command execution.
* `-N`: Do not execute a remote command.  This is useful for just forwarding ports.
-----

<br></br>

## Remote Port forwarding

* SSHトンネルを経由して、リモートマシンとの間でセキュアに暗号化された通信が行われます。
* Remote machineのローカルポートへのトラフィックを、Local machineのローカルポートへ転送します。
* 例えば、Local環境のweb serverへRemote machineからアクセスできるようにすることが可能です。

Local machineにおいて、web serverをlocalhost:80で公開する。

```
sudo python3 -m http.server --bind 127.0.0.1 80 &
```

<div align="center">
<img src="./ssh4.svg">
</div>

* Local Local machine内のlocalhost:80からアクセスできるweb serverがある。もちろん、Remote machineからはアクセスできない。
* Local machineからremote machineへはsshでアクセスできる。= 通信を暗号化する安全なssh tunnelを確立できる。

Remote Port forwardingを実行するには、以下コマンドをLocal machine上で実行する必要がある。

```
ssh -R localhost:8080:localhost:80 root@$REMOTE_IP
```

このコマンドは、Remote machineのlocalhost:8080へのtrafficをlocal machineのlocalhost:80にforwardすることを意味する。

* `-R`: 
* `localhost:8080:localhost:80` = (`remote address:local address`)
  * remote address tells sshd server where to start listening.
  * local address  tells ssh client where to forward traffic to.

Remote machineのlocalhost:8080にアクセス(`curl localhost:8080`)と、Local machineの`localhost:80`にアクセスできる。

<div align="center">
<img src="./ssh5.svg">
</div>

Remote machineのloopback addressだけでなく、他のinterfaceのIP addressをport fowardingすることも可能である。

```
ssh -R $REMOTE_IP:8080:localhost:80 root@$REMOTE_IP
```

<div align="center">
<img src="./ssh6.svg">
</div>

Remote Machineの$REMOTE_IPへのアクセス(`curl $REMOTE_IP:8080`)が可能である。

ただし、Remote machine内の`/etc/ssh/sshd_config`の`GatewayPorts yes`としないと、自動的にlocalhostが転送対象とされてしまうので注意が必要である。

-----
GatewayPorts (man sshd_config)
--

By default, sshd(8) binds remote port forwardings to the loopback address. This prevents other remote hosts from connecting to forwarded ports. GatewayPorts can be used to specify that sshd should allow remote port forwardings to bind to non-loopback addresses, thus allowing other hosts to connect.

-----

<br></br>

## _References_

* [A Visual Guide to SSH Tunnels: Local and Remote Port Forwarding](https://iximiuz.com/en/posts/ssh-tunnels/)