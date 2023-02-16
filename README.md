# Replica Placement Constraints Updater Script
The script in this repo can be used to update Multi Region Cluster assignments for Confluent Clusters.
Some topics created as default will not honor the Replica Placement constraints. 
You can use this script to automate the replica placement assignment for all the necessary topics.

# Run the script

```
# Generate the list of topics file 
./replica_placement_utils.sh --bootstrap-server localhost:9092 --list-topic
# Apply the new replica placement to the generated list (default: without_placement.txt)
./replica_placement_utils.sh --bootstrap-server localhost:9092 --replica-placement-filepath sample_replica_assignment.json  --execute 
# Apply to a different list of topics file 
./replica_placement_utils.sh --bootstrap-server localhost:9092 --replica-placement-filepath sample_replica_assignment.json  --execute --topics-filepath custom.list.txt
# With command-config
./replica_placement_utils.sh --bootstrap-server localhost:9092 --list-topic --command-config client.config
./replica_placement_utils.sh --bootstrap-server localhost:9092 --replica-placement-filepath sample_replica_assignment.json  --execute --command-config client.config
```