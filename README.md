# Astrolab Brain

This service coordinates everything the Astrolab does. It provides API endpoints for Astrolab services to talk to, and an interface through which AstroSwarm can control the Astrolab.

## Environment Variables

* `ASTROSWARM_API_HOST` is the hostname and port of the AstroSwarm API.
* `HOST_DATA_DIR` is a directory containing files about the host, which should be mounted by the host upon container creation.
* `RACK_ENV` is the environment in which this service runs ("development" or "production").
