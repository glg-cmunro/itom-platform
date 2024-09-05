# ![GreenLight Group Logo](https://assets.website-files.com/5ebcb9396faf10d8f7644479/5ed6a066891af295a039860f_GLGLogolrg-p-500.png)
# GreenLight Group - How To - Setup your AWS Profile

## Document Purpose
This How-To document provides a step-by-step guide to clear pulsar queues that are backing up OPTIC Reporting.

---

# Check the Queue:
```
sudo kubectl exec -ti omi-0 -n opsb-helm -c omi -- /opt/HP/BSM/opr/bin/opr-event-sync.sh -list
```

# Clear the Queue:
```
sudo kubectl exec -ti omi-0 -n opsb-helm -c omi -- /opt/HP/BSM/opr/bin/opr-event-sync.sh -clear -identifier itom-di-receiver-svc:lxo-opticcntrl.afcucorp.local -force
```
```
sudo kubectl exec -ti omi-0 -n opsb-helm -c omi -- /opt/HP/BSM/opr/bin/opr-event-sync.sh -clear -identifier itom-di-receiver-svc
```

# Clear Pulsar:
```
sudo kubectl exec -ti itomdipulsar-bastion-0 -n opsb-helm -c pulsar -- ./bin/pulsar-admin namespaces clear-backlog public/default
```


# Clear the Browser:
Login to OMi

Open View --> All Events
Set Filter for 'Event Forwarding'
