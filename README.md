# solidus_dockerfiles
Collection of different examples for Running Solidus with Docker containers

These images can be used to build your own Production-ready Solidus images

```
# image size against the solidus_demo repository
sass/solidus-alpine                                       latest          2a8a4e6961b8   9 minutes ago   655MB
sass/solidus                                              latest          67a2bfe63388   22 hours ago    1.72GB
```

You can use the example `docker-entrypoint.sh` and customize to your needs (say if you want to run a parallel process with Rails)

## Cheatsheet

You can build the images by using the following:

```sh
docker build --build-arg RUBY_VERSION=2.6.6 \
 --build-arg PG_VERSION=13 \
 --build-arg NODE_VERSION=14 \
 --build-arg BUNDLER_VERSION=2 \
 -f ruby-slim-sample.Dockerfile 
 -t repo/solidus .

docker build --file alpine.Dockerfile -t repo/solidus-alpine .
```

Run the containers using the following commands

```sh
docker run -it \
 -e RAILS_ENV=production \
 -e DATABASE_URL="postgresql://postgres:passs@localhost:5432?sample-dev-production" \
 -e SECRET_KEY_BASE=example \ # omit if not necessary, ie included in your credentials
 -e RAILS_MASTER_KEY=123 \ # omit if not necessary
 -e RAILS_LOG_TO_STDOUT=true \
 -e RAILS_SERVE_STATIC_FILES=true \
 -v $PWD:/home/solidus_demo_user/app \ # not necessary but interesting locally if you want to say, edit rails credentials:edit
 -p 3000:3000 base/solidus
```