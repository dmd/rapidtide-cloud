# rapidtide-cloud
Tool to run [Rapidtide](https://github.com/bbfrederick/rapidtide) on HCP/ABCD datasets, on AWS, consisting of a CloudFormation template, some helper/test scripts, and a Dockerfile which extends rapidtide to work with AWS.

Currently this is a bit of a mix of "stuff to build this tool" and "the tool itself" - that will be cleaned up when this is all eventually merged into rapidtide itself.

Parameters (either to the stack or the batch):

- `HcpOpenaccessSecret` (required): the ARN to an AWS Secret containing your hcp-openaccess bucket credential in a AWS Secret in *plain text* `KEY:SECRET` form
- `OutputBucket`: (required): The S3 bucket your output will be written to.

Parameters (to the batch):

- `ParticipantArrayFile`: (optional) The filename within OutputBucket/config which contains a list of participants to process in an Array job. Defaults to `participants.txt`. You could change this to run several different batches and keep track of which ones have which participants.

## Getting started

[Install the AWS CLI toolkit](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and run `aws configure`. 

### Save your hcp credentials into an AWS Secret.

You should have an *Access Key ID* and *Secret Access Key* which grant you access to the *hcp-openaccess* bucket.

Suppose your key and secret are:

| key | secret |
| --- | --- |
| AKIAABCDEFGHIJKL4MNO | s1gz+fooBARbazQUUX |

Then run:

```bash
aws secretsmanager create-secret \
    --name HCP_OPENACCESS \
    --secret-string "AKIAABCDEFGHIJKL4MNO:s1gz+fooBARbazQUUX"
```

This will respond with something like:

```json
{
    "ARN": "arn:aws:secretsmanager:us-east-1:123456789:secret:HCP_OPENACCESS-ezUaOI",
    "Name": "HCP_OPENACCESS",
    "VersionId": "be3505ba-1234-abcd-6789-12346b770bc6"
}
```

Copy down the `ARN`.

### Create a bucket for your output.

**TODO document**

### Create your Cloudformation stack.

Pick a name for your stack, e.g. MyRapidtideStack. It doesn't matter what it is.

Run:

```bash
./awsstack-create MyRapidtideStack YourBucketName YourARN
```

where YourARN is the long `arn:aws...` string you copied down above.

## Test!

Once your stack is created you're ready to submit a test job. Run:

```bash
aws batch submit-job \
    $(./batch-stack-info MyRapidtideStack) \
    --job-name myFirstJob \
    --container-overrides command="/simple-cp-test"
```

Head over to the [Batch console](https://us-east-1.console.aws.amazon.com/batch) and see how it goes. 
