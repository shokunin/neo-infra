## Node Count by Key

```
MATCH (n:SshKey)-[r:sshkey]-(i:Node) WITH n, count(i) as node_count RETURN n.name, node_count ORDER by node_count DESC
```

## Ports open to the Internet

```
MATCH (i:IpRules{cidr_block: "0.0.0.0/0"})-[r:ip_rules]-(s:SecurityGroup)-[p:node_sg]-(n:Node) WITH i, count(n) as node_count RETURN i.proto, i.from_port, i.to_port, i.direction,i.cidr_block, node_count  ORDER by node_count DESC
```

## Ports open
```
MATCH (i:IpRules)-[r:ip_rules]-(s:SecurityGroup)-[p:node_sg]-(n:Node) WITH i, count(n) as node_count RETURN i.proto, i.from_port, i.to_port, i.direction,i.cidr_block, node_count  ORDER by node_count DESC
```

## Find all nodes that will take a priveleged port

```
MATCH (i:IpRules)-[r:ip_rules]-(s:SecurityGroup)-[p:node_sg]-(n:Node) WHERE i.from_port >= 1 and i.to_port <= 1024 RETURN i.proto, i.from_port, i.to_port, i.direction,i.cidr_block, n.name, count(n.name)  ORDER by count(n.name) DESC
```
