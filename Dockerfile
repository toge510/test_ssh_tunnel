FROM ubuntu:22.04
RUN apt update && apt install -y openssh-server curl
RUN mkdir /root/.ssh /tmp/ssh 
COPY entrypoint.sh entrypoint.sh
RUN chmod 755 entrypoint.sh
CMD ["./entrypoint.sh"]