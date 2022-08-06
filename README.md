# cra-docker-traefik

How to run a Create React App for development using Docker and Traefik

## Create the Project's Folder

As first step, let's just initialize a new project.

I usually do that by creating a new repo under [my GitHub's account][marcopeg] so that I can easily scaffold it with a basic README and LICENCE file.

Once I'm done, I clone it and get into my project's root:

```bash
# Clone my Project:
git clone git@github.com:marcopeg/cra-docker-traefik.git

# Get into the Project's root:
cd cra-docker-traefik

# Start VSCode on my Project:
code .
```

## Create (a) React App

Over the years I tried many approaches to running a Webpack based App with React. Eventually I settled for [Create React App][cra].

It doesn't give me everything I want, or the way I'd have done it myself, but it takes away most of the hassles of running a modern React-based projects and let me focus on my business logic.

```bash
# Add a React App to my Project
npx create-react-app .
```

Usually, I would run an `npm start`, open `http://localhost:3000` on my [Google Canary][canary], and start writing my components.

But today, the goal is different:

1. run `docker-compose up` to start my system
2. open `http://app.localhost` on my browser

## Build the Developement Container

There is much literature about running a development container for Webpack and React. Luckily, things got much easier lately.

I like the approach with a custom `Dockerfile` that is responsible for installing the NPM Dependencies:

```Dockerfile
# ----------
# Dockerfile
# ----------

FROM node:16

# Install NPM dependencies:
WORKDIR /usr/src/app
ADD package.json /usr/src/app
RUN npm install

# Run the App:
WORKDIR /usr/src/app
ENTRYPOINT [ "npm", "run", "start" ]

# Configure the Container:
EXPOSE 3000
```

> Explicitly exposing port `3000` helps us flowing CRA's default values to the Traefik's reverse proxy, effectively _DRY_-ing the configuration that we need to maintain.

It is important to pair this file with a `.dockerignore` as so to optimize the amount of data that are passed to the Docker's daemon during the build:

```bash
# -------------
# .dockerignore
# -------------

node_modules
build
```

The two files put together, describe to Docker how to build our Development Container.

> Please note that we didn't copy the source code. The `public/` and `src/` folders will be linked at run time by Docker-Compose.

We can test the build by running:

```bash
docker build .
```

## Run the Docker-Compose Project

[Docker-Compose][dc] offers a simple interface for running projects with one or multiple containers. 

I use it even for my simplest projects because I appreciate the **declarative nature** of it `docker-compose-yml`:

```yaml
# ------------------
# docker-compose.yml
# ------------------

version: "3.8"
services:
  app:
    build: .
    volumes:
      - ./public:/usr/src/app/public:delegated
      - ./src:/usr/src/app/src:delegated
    tty: true
    ports:
      - "3000:3000"
```

The `build .` instruction let Docker-Compose know that we want it to use a custom container using the `Dockerfile` and `.dockerignore` that we've prepared.

The `volumes:` instruction let us link the Project's source folders into the running container so that any change we make will be immediately picked up by the Webpack running inside such container.

`tty` makes the logs nice to read but it is not required.

Finally, the `ports:` instruction links the process running inside the container to one of our computer's ports. 

> We are going to remove this instruction later on, when we get to the Traefik reverse proxy part.

To test that all is running properly you just need to run:

```bash
docker-compose up
```

Open your browser to `http://localhost:3000` and enjoy a fully working React App.

Also, try to modify `arc/App.js` to prove that the hot-reload is properly working for you.

## Adding New Dependencies

The approach with a

## Add the Reverse Proxy

[Traefik][traefik] is the new cool kid in the block when it comes to proxies. Under many aspects, it makes NGiNX feels like a dinosour from the ancient times when we still used to write endless config files.

First, let's add a Traefik container to our `docker-compose.yml`:

```yml
# ------------------
# docker-compose.yml
# ------------------

version: "3.8"
services:

  traefik:
    image: "traefik:v2.8"
    command: "--api.insecure --providers.docker"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
    ports:
      - "80:80"
      - "8080:8080"
```

This piece of compose config is basically taken straight out of the official documentation:  
https://doc.traefik.io/traefik/user-guides/docker-compose/basic-example/

> The combination of `--api.insecure=true` and exposing `port 8080` let you access the Traefik's console by aiming your browser to: `http://localhost:8080`. 
>
> You don't technically need it to expose the React App, and you **definetly** don't expose it when running in production!

## Proxy the React App

The last piece of the puzzle is to properly configure the access to the React App. 

Since we use Docker and Traefik, we can do it by adding labels to the `app`'s container:

```yml
# ------------------
# docker-compose.yml
# ------------------

version: "3.8"
services:

  app:
    labels:
      - "traefik.http.routers.app.rule=Host(`app.localhost`)"
```

🙌 Restart the project and enjoy your React App available at `http://app.localhost`.

> `localhost` comes as preconfigured routed host name in most systems. If it doesn't work, you may need to edit the `/etc/hosts` file.

## Set a Custom Domain

Now that you have a [full `docker-compose.yml`](./docker-compose.yml) to play with, you may want to start messing around with custom domains.

Let's say that your App should end up working on `http://foobar.com`, and you want to use this particular DNS while developing.

First, you can adjust your Host setting in the container's lable:

```
traefik.http.routers.app.rule=Host(`foobar.com`)
```

Second, you shoud [edit your `/etc/hosts`](https://www.google.com/search?q=how+to+edit+etc%2Fhosts) adding the rule:

```
127.0.0.1 foobar.com
```

🙌 Restart the project, and enjoy your React App available at `http://foobar.com`.

