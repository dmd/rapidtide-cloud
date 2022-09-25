# rapidtide-hcp-cloud
Tool to run Rapidtide on HCP/ABCD datasets, on AWS.


Requirements:

- must attach an IAM role which has access to
  - S3
  - Secrets Manager
- must have the hcp-openaccess key/secret in a AWS Secret named `hcp-openaccess` under keys `KEY` and `SECRET`