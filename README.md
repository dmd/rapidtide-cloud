# rapidtide-cloud
Tool to run [Rapidtide](https://github.com/bbfrederick/rapidtide) on HCP/ABCD datasets, on AWS.
This will eventually be merged into rapidtide itself.

Parameters (either to the stack or the batch):

- HcpOpenaccessSecret (required): the ARN to an AWS Secret containing your hcp-openaccess bucket credential in a AWS Secret in *plain text* `KEY:SECRET` form
- OutputBucket: (required): The S3 bucket your output will be written to.
- ParticipantArrayFile: (optional) The filename within OutputBucket/config which contains a list of participants to process in an Array job. Defaults to `participants.txt`.
