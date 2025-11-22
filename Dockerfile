# demo-image/Dockerfile
FROM busybox:latest
LABEL maintainer="example"
CMD ["echo", "Hello from a signed image!"]
