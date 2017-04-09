default: build

configure:
	uname -m | grep arm && echo "FROM resin/rpi-raspbian:jessie" > Dockerfile || echo "FROM debian:jessie" > Dockerfile
	cat Dockerfile_template >> Dockerfile

build: configure
	docker build ./

clean:
	rm Dockerfile