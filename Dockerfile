FROM fredericklab/rapidtide:latest
USER root
RUN apt-get -y update && apt-get -y install s3fs awscli jq
RUN mkdir /data_in /data_out
COPY rapidtide-cmd mount-and-run simple-cp-test /
ENTRYPOINT ["/mount-and-run"]
