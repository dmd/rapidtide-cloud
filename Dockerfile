FROM fredericklab/rapidtide:latest
USER root
RUN apt-get -y update && apt-get -y install s3fs
RUN mkdir /data_in /data_out
COPY rapidtide-cmd mount-and-run /
ENTRYPOINT ["/mount-and-run"]
