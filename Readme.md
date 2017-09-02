# neo-infra


## Auditing

To audit resources to ensure that they are properly tagged run

```
rake audit_all
```

See the tag_policy section of the config.yaml.example file for ideas

## Running

1) Download and run neo4j container

```
docker run --rm \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$HOME/tmp/neo4j/data:/data \
    --volume=$HOME/tmp/neo4j/logs:/logs \
    -e NEO4J_AUTH='none' \
    neo4j:3.1.4
```

2) Copy the config.yaml.example file to config.yaml and add in account information

```
cp config.yaml.example config.yaml
```

3) Run bunder

```
bundle install
```

4) Run the data loader

```
rake load_all
```

5) Point your web browswer at http://localhost:7474


## Example Queries

All S3 buckets by size
```
MATCH (n:Bucket)-[o:owner]-(a:AwsAccount) RETURN n.name, n.size, a.name ORDER by n.size DESC
```

List out all subnets by instance count
```
MATCH (i: Node)-[r:subnet]-(s:Subnet)-[q:subnet]-(v:Vpc)-[o:owned]-(a:AwsAccount) WITH s, v, a, count(i) as nc RETURN s.cidr, v.name, a.name, nc ORDER by nc DESC
```
