# SPARQL  experiments with Docker Compose and IGUANA for Virtuoso and eLDS

This [Docker Compose](https://www.docker.com/docker-compose) package contains an [IGUANA](https://github.com/AKSW/IGUANA) benchmarking environment for [Virtuoso](http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/) and [eLDS](https://www.eccenca.com/de/produkte/linked-data-suite.html).

## Requirements

- [Docker](http://docker.com/)
- [Docker Compose](https://www.docker.com/docker-compose)
- access to eccenca docker-registry (`docker login -u USER -e MAIL https://docker-registry.eccenca.com`)


## Usage

To start a default test, clone this repository, change into its folder and run:

`docker-compose up`

This will start two instances of Virtuoso and one eLDS, import some data and run a IGUANA benchmark on the first Virtuoso and on eLDS with the second Virtuoso. The benchmark results get stored to `./Results/`.

The results are CSV statistics and diagrams for the succeeded/failed etc. queries. Each store is listed as a row and every query (see `./IGUANA/queries.txt`) in a column (indicated with 0,1,...).

## Multiple Tests

To automatic run multiple test, you can use the `test.sh` script. For example, run:

`./test.sh 10`

to start 10 tests. All results will moved to `./Results/Test-[number]`


# The Docker Images

## Virtuoso

Setup Virtuoso from 'aksw/dld-store-virtuoso7' as given in the sample docker Compose files.

**Docker Compose Part:**

```
store:
  image: aksw/dld-store-virtuoso7
  expose:
    - "8890"
    - "1111"
  environment:
    PWDDBA: "dba"
  volumes:
    - ./Import:/import_store
```

*Description:*

- image from Docker Hub
- volume to import data

## Loader

The folder `./Import/` contains RDF files (format can be ttl, nt, ...) to import. The graph will be extracted from filename (example: test.nt goes to http://test/). If you need a specific graph, just create a file `[filename].[filextension].graph` which only contains the base URI as string.

*Example:*

`Import/my-data.nt` (RDF-Data)

`Import/my-data.nt.graph` (Graph, content: http://my-graph-uri/)

**Docker Compose Part:**

```
loader:
  image: aksw/dld-remoteload-virtuoso
  links:
    - store
  expose:
    - "80"
  environment:
    - STORE_1=uri=>http://%%store%%:1111 type=>virtuoso user=>dba pwd=>dba
  volumes:
    - ./Import:/import_store
```

*Description:*

- links to the target import stores
- expose port 80 for IGUANA
- environments to the target import stores (see section "Stores as Environment")
- volume to the import data folder

## eLDS

**IMPORTANT:** Currently eLDS must allow **anonymous access** (set `anonymous: true` in section userAuth or disable it) to give IGUANA access rights. If you're planing to use your own eLDS you have to consider that. IGUANA uses the [Jena JDBC Lib](https://jena.apache.org/documentation/jdbc/drivers.html#authentication), which realized HTTP authentication like Basic and Digest. The state of implementing OAuth in IGUANA can be followed in [issue 30](https://github.com/AKSW/IGUANA/issues/30).

To use this repository, a login to eccenca docker-registry is required. (`docker login -u USER -e MAIL https://docker-registry.eccenca.com`)

**Docker Compose Part:**

```
elds:
   image: docker-registry.eccenca.com/elds-backend
   links:
     - store
   expose:
     - "80"
   volumes:
     - ./eLDS-DataPlatform:/data
```

*Description:*

- links to the store
- expose port 80 for IGUANA
- volume `./eLDS-DataPlatform:/data` for the config files

### Configuration

The configuration file `application.yml` for eLDS contains the access config for the store. If you change the store config (such as password), you have to adobt this file.


## IGUANA

The IGUANA container waits until all stores and the loader are done, starts a benchmark test on each given store and writes the results to `./Results`.

If the startup for stores or data-import needs to much time and this container have a timeout, you can increase the attempts by set `CONNECTION_ATTEMPTS=60` (default=30) as environment.

**Docker Compose Part:**

```
iguana:
  image: aksw/dld-present-iguana
  links:
    - store
    - loader
  environment:
    - STORE_1=uri=>http://%%store%%:8890/sparql type=>virtuoso user=>dba pwd=>dba
    # - CONNECTION_ATTEMPTS=60
  volumes:
    - ./Results:/iguana/results
    - ./IGUANA:/iguana/config
```

*Description:*

- links to the benchmarking stores, elds-backend and loader (if enabled)
- environments to benchmarking stores and elds-backend (if used)
- volumes to the confif and results folder

### Configuration

To use your own configuration, please have a look at `./IGUANA/`, which contains the `config.xml` and `queries.txt` to setup the test-queries and the store.

Have a look at [Dockerizing/IGUANA Readme.md](https://github.com/Dockerizing/IGUANA/blob/master/README.md) for more detailed information about the usage and configuration.


## Stores as Environment

To pass stores to the Loader, eLDS and IGUANA, they must be given as environment variables. Stores can be other containers of this Docker Compose package or your own servers/endpoints.

**Docker Compose Example:**

```
environment:
    - STORE_1=uri=>dbpedia.org/sparql type=>dbpedia
    - STORE_2=uri=>your-ip:8890/sparql type=>virtuoso user=>dba pwd=>dba
```

The STORE_index is an increasing number, beginning from 1.

To use the URI of an store of this Docker Compose environment, use the placeholder `%%container-id%%`. 

**Docker Compose Example:**

```
# 'store' is our container id
store
  image: aksw/dld-store-virtuoso7
  expose:
    - "8890"
    - "1111"

iguana:
  image: aksw/dld-present-iguana
  links:
    - store
  environment:
    # use '%%store%%' as reference to the store-container
    - STORE_1=uri=>http://%%store%%:8890/sparql type=>virtuoso user=>dba pwd=>dba
```


The keys for the STORE_index variable are:

+ `uri` - (required) Server uri or store-id. To match a docker-compose container, use %%store_id%%, store_id is the unique name of your store, given in your compose file.
+ `type` - type of our store (e.g. 'virtuoso')
+ `user` - store user if required
+ `pwd` - store password if required