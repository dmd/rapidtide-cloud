FROM fredericklab/rapidtide:latest

USER root

COPY rapidtide-cmd mount-and-run simple-cp-test /

ENTRYPOINT ["/mount-and-run"]
