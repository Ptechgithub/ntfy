## ntfy | Send push notifications to your phone or desktop via PUT/POST


## install
```
bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/ntfy/main/install.sh)
```


- Example commands (type ntfy user --help or ntfy user COMMAND --help for more details):


```

ntfy user list                     # Shows list of users (alias: 'ntfy access')
ntfy user add USER-NAME                 # Add regular user USER-NAME  
ntfy user add --role=admin USER-NAME    # Add admin user USER-NAME
ntfy user del USER-NAME                 # Delete user USER-NAME
ntfy user change-pass USER-NAME         # Change password for user USER-NAME
ntfy user change-role USER-NAME admin   # Make user USER-NAME an admin
ntfy user change-tier USER-NAME pro     # Change USER-NAME's tier to "pro"

ntfy access                            # Shows access control list (alias: 'ntfy user list')
ntfy access USER-NAME                   # Shows access control entries for USERNAME
ntfy access USER-NAME TOPIC PERMISSION  # Allow/deny access for USERNAME to TOPIC
ntfy access USER-NAME TOPIC rw   # Give (read-write) access for USERNAME to TOPIC

```

A PERMISSION is any of the following supported permissions:

read-write (alias: rw): Allows publishing messages to the given topic, as well as subscribing and reading messages
read-only (aliases: read, ro): Allows only subscribing and reading messages, but not publishing to the topic
write-only (aliases: write, wo): Allows only publishing to the topic, but not subscribing to it
deny (alias: none): Allows neither publishing nor subscribing to a topic


```
curl -d "send your message " url/topic

curl -u USER-NAME:PASSWORD -d "send your message " url/topic
```
