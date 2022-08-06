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