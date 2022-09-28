FROM fredericklab/rapidtide:latest

USER root

COPY rapidtide-cmd mount-and-run simple-cp-test get-array-line /

ENTRYPOINT ["/mount-and-run"]
