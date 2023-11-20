# Orangetheses
[![Circle CI](https://circleci.com/gh/pulibrary/orangetheses.svg?style=svg)](https://circleci.com/gh/pulibrary/orangetheses)
[![Apache 2.0 License](https://img.shields.io/badge/license-Apache%202.0-blue.svg?style=plastic)](./LICENSE)

Ruby Gem used for harvesting OAI-PMH records, transforming these into Solr Documents, and indexing the Documents.

## Installation

```
$ gem install orangetheses
```

## Usage

### Indexing an individual OAI-PMH record from DataSpace
```
# oai:dataspace.princeton.edu:88435/dsp012z10wq21r is the OAI-PMH record identifier
$ rake oai:index_record[oai:dataspace.princeton.edu:88435/dsp012z10wq21r] SOLR="http://127.0.0.1:8983/solr/blacklight-core"
```

### Indexing the Senior Theses collection records from DataSpace
```
$ rake orangetheses:index_all SOLR="http://127.0.0.1:8983/solr/blacklight-core"
```

### Locally saving the Solr Documents for Senior Theses collection records from DataSpace
```
$ rake orangetheses:cache_theses FILEPATH=/tmp/theses.json
```

### Indexing the visual resource collection records from PUL websites
```
$ rake orangetheses:index_visuals SOLR="http://127.0.0.1:8983/solr/blacklight-core"
```

## Development

#### Setup
* Install Lando from https://github.com/lando/lando/releases (at least 3.0.0-rrc.2)
* See .tool-versions for language version requirements (ruby)

```bash
bundle install
```
(Remember you'll need to run the above commands on an ongoing basis as dependencies are updated.)

#### Starting / stopping services
We use lando to run services required for both test and development environments.

Start and initialize Apache Solr with `rake servers:start`

To stop Solr services: `rake servers:stop` or `lando stop`

#### Run tests
```bash
$ bundle exec rspec
```

#### Installing the Gem
To install this Gem onto your local machine, please run:

```bash
$ bundle exec rake install
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pulibrary/orangetheses.
