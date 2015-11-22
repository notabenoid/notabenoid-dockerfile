# notabenoid-dockerfile

## Usage

### Building the image

    docker build -t notabenoid .

### Running the image (it will listen on 127.0.0.1:8080)

    docker run -p 127.0.0.1:8080:80 --name notabenoid notabenoid

Or, alternatively, skip the building step and use the image uploaded to the Docker Hub (you also don't need to clone the notabenoid-dockerfile repository for this to work):

    docker run -p 127.0.0.1:8080:80 --name notabenoid opennota/notabenoid

## Development

From this point on I'm assuming that you already have built an image named `notabenoid`.

On the host machine, clone the notabenoid repository and `cd` to it:

    git clone https://github.com/notabenoid/notabenoid.git
    cd notabenoid

Start the container using the current directory as a volume and replacing the existing `/notabenoid/site` directory inside the container:

    docker run -v `pwd`:/notabenoid/site -p 127.0.0.1:8080:80 --name notabenoid notabenoid

Now you can edit the code outside of the container with your favorite editor.
