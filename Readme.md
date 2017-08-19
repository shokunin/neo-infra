# neo-infra

## Running

Download and run the APOC Docker image of Neo4j

```
mkdir plugins
pushd plugins
wget https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/3.1.3.7/apoc-3.1.3.7-all.jar
popd

docker run --rm \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$HOME/tmp/neo4j/data:/data \
    --volume=$HOME/tmp/neo4j/logs:/logs \
    --volume=$PWD/plugins:/plugins \
    -e NEO4J_AUTH='none' \
    neo4j:3.1.4
```
