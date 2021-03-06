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
    -e NEO4J_AUTH='none' \
    neo4j:3.1.4
```

2) Copy the config.yaml.example file to config.yaml and add in account information

```
cp config.yaml.example config.yaml
```

3) Run bundler

```
bundle install
```

4) Run the data loader

```
rake load_data:all
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

Find all non-default VPCs ordered by instance count
```
MATCH (n:Vpc) OPTIONAL MATCH  (n)<-[:subnet]-(:Subnet)<-[:subnet]-(x:Node) WITH count(x) as node_count, n WHERE n.default="false" RETURN n.name, n.default, node_count ORDER by node_count DESC
```
