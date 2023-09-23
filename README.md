```
bash <(curl -fsSL https://raw.githubusercontent.com/Ptechgithub/ntfy/main/install.sh)
```


- Example commands (type ntfy user --help or ntfy user COMMAND --help for more details):

``
ntfy user list                     # Shows list of users (alias: 'ntfy access')
ntfy user add USER-NAME                 # Add regular user USER-NAME  
ntfy user add --role=admin USER-NAME    # Add admin user USER-NAME
ntfy user del USER-NAME                 # Delete user USER-NAME
ntfy user change-pass USER-NAME         # Change password for user USER-NAME
ntfy user change-role USER-NAME admin   # Make user USER-NAME an admin
ntfy user change-tier USER-NAME pro     # Change USER-NAME's tier to "pro"
sudo ntfy access USER-NAME TOPIC rw   # Give access to a specific topic
``

``
curl -u USER-NAME:PASSWORD -d "send your message " url/topic
``