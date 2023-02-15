# Replica Placement Constraints Updater Script
The script in this repo can be used to update Multi Region Cluster assignments for Confluent Clusters.
Some topics created as default will not honor the Replica Placement constraints. 
You can use this script to automate the replica placement assignment for all the necessary topics.

# How to launch the script
```
./assignReplicaConstraints.sh --bootstrap-server localhost:9092 --replica-placement-filepath sample_replica_assignment.jso
```

Once the script is running it will produce a `xxxx_alltopics.txt`. You can edit this file to apply the placement on a subset of these topics.

i.e.

```
============================================================================
Bootstrap Servers are: localhost:9092
Replica Placement file is: sample_replica_assignment.json
============================================================================
Getting the list of topics
Executing without Command Config
============================================================================
The output of this step is available in /Users/prametta/ps/mrc_replica_assignment/1676448117_alltopics.txt
If there are multiple unwanted lines due to some issues in java execution, remove them from the file before proceedding to the next step.
============================================================================
Press enter to continue once you have validated the file and are happy to proceed further.
```


