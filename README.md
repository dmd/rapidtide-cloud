# rapidtide-cloud
Tool to run [Rapidtide](https://github.com/bbfrederick/rapidtide) on HCP/ABCD datasets, on AWS, consisting of a CloudFormation template, some helper/test scripts, and a Dockerfile which extends rapidtide to work with AWS. This will eventually be merged into Rapidtide proper.


Parameters:

- `OutputBucket`: (required): The S3 bucket your output will be written to.
- `ParticipantArrayFile`: (optional job parameter) The filename within OutputBucket/config which contains a list of participants to process in an Array job. Defaults to `participants.txt`. You could change this to run several different batches and keep track of which ones have which participants.

## Getting started

[Install the AWS CLI toolkit](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and run `aws configure`. 

### Create a bucket for your output.

**TODO document**

### Create your Cloudformation stack.

Run: `./awsstack-create` and follow the prompt to enter a stack name and your S3 output bucket name.

## Test!

Once your stack is created you're ready to submit a test job. Run:

```bash
aws batch submit-job \
    $(./batch-stack-info MyRapidtideStack) \
    --job-name myFirstJob \
    --container-overrides command="/simple-cp-test,100307"
```

Head over to the [Batch console](https://us-east-1.console.aws.amazon.com/batch) and see how it goes. 
