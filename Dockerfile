FROM  ubuntu:latest

# Install the application dependencies
COPY . /app

WORKDIR /app

CMD ["/bin/bash"]


