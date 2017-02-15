FROM golang:1.7.5

ENV PROJECT_EXECUTABLE fun-swarm-scheduler
ENV PROJECT_NAME github.com/seriousben/fun-swarm-scheduler
ENV PROJECT_SRC /go/src/fun-swarm-scheduler

RUN mkdir -p $PROJECT_SRC
COPY . $PROJECT_SRC
RUN go get -u github.com/kardianos/govendor && cd $PROJECT_SRC && govendor install

ENTRYPOINT /go/bin/fun-swarm-scheduler

EXPOSE 8484
