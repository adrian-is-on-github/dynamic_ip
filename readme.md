# readme #

### This little script updates an IP address record in AWS Route53 ###

### Why? ###
- Running little services at home?
- Want to access them on the move?
- Don't want to pay for a static IP address?
- Here's your use case.

### What Does it Do? ###
- Requests your public IP from ipinfo.io
- Validate to make sure you've actually gotten a real IP address from ipinfo.io
- Checks to see if it matches the last IP in the logs
- If it's different, it'll send an API request to AWS Route53
  `aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE --change-batch file://~/route53_update.json`
- It logs everything substantial into `ip_update.log`

### What Does it Need? ###
- AWS CLI setup on the machine
- Route53 Hosted zone
- Route53 Hosted zone ID
- An IP address record which supports IP addresses (A record if you're doing basic stuff)
- You to occasionally check in to see how it's behaving
