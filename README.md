# notabenoid-dockerfile

## Usage

### Building the image

    docker build -t notabenoid .

### Running the image (it will listen on 127.0.0.1:8080)

    docker run -p 127.0.0.1:8080:80 --name notabenoid notabenoid

Or, alternatively, skip the building step and use the image uploaded to the Docker Hub (you also don't need to clone the notabenoid-dockerfile repository for this to work):

    docker run -p 127.0.0.1:8080:80 --name notabenoid opennota/notabenoid

