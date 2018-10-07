# Astrolab Brain

This service coordinates everything the Astrolab does. It provides API endpoints for Astrolab services to talk to, and an interface through which AstroSwarm can control the Astrolab.

## Environment Variables

* `ASTROSWARM_API_HOST` is the hostname and port of the AstroSwarm API.
* `HOST_DATA_DIR` is a directory containing files about the host, which should be mounted by the host upon container creation.
* `RACK_ENV` is the environment in which this service runs ("development" or "production").

## Running the specs

After building astrolab locally, run:

```bash
./build
cd ../astrolab
docker-compose run --rm -e RACK_ENV=test brain rbenv exec bundle exec rspec spec
```

To relaunch from the astrolab context, use:

```bash
cd ../astrolab
docker-compose up -d brain
```

## Useful curl commands:

* Download and run PHD2 with: `curl -X POST -d '{"image": "astroswarm/phd2:latest"}' http://localhost:5000/api/start_xapplication`
* Stop PHD2 with `curl -X POST -d '{"image": "astroswarm/phd2:latest"}' http://localhost:5000/api/stop_xapplication`
* Clean PHD2 and remove all stored user data: `curl -X POST -d '{"image": "astroswarm/phd2:latest"}' http://localhost:5000/api/clean_xapplication` 