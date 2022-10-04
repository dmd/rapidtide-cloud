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

Run: `./awsstack-create` and follow the prompts. You will:

- choose a unique-to-you stack name
- enter the name of your previously created S3 output bucket
- enter your HCP Open Access credentials

## Test!

Once your stack is created you're ready to submit a test job. Run:

```bash
aws batch submit-job \
    $(./batch-stack-info) \
    --job-name myFirstJob \
    --container-overrides command="/simple-cp-test,100307"
```

This will output some information about the created job - you may need to press `q` to exit. (You can prevent this in the future by putting `export AWS_PAGER=` in your `.bashrc`.)

Head over to the [Batch console](https://us-east-1.console.aws.amazon.com/batch) and see how it goes. 

## Run an ARRAY job

In your output bucket, create a directory called `config`, and inside it a file called `participants.txt`.  Each line of that file should be a HCP participant number.

Run:

```bash
aws batch submit-job \
    $(./batch-stack-info) \
    --job-name myFirstArrayJob \
    --array-properties size=5 \
    --container-overrides command="/simple-cp-test,ARRAY"
```

The number given to `size=` must be <= the number of lines in `participants.txt`.
