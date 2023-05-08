# rapidtide-cloud
Tool to run [Rapidtide](https://github.com/bbfrederick/rapidtide) on HCP/ABCD datasets, on AWS, consisting of a CloudFormation template and some helper/test scripts.

## Getting started

[Install the AWS CLI toolkit](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and run `aws configure`. 

### Special considerations for SSO

**If and only if you use your organization's SSO to log into AWS**, you need to run

```
aws configure sso
```

When login completes, you will see output ending in something like:

```
To use this profile, specify the profile name using --profile, as shown:

aws s3 ls --profile AWSAdministratorAccess-12345678912
```

Whatever that label is after `--profile`, make a note of it, and then execute the following commands, substituting that label in:

```
eval "$(aws configure export-credentials --profile AWSAdministratorAccess-12345678912 --format env)"
export AWS_PROFILE=AWSAdministratorAccess-12345678912
```

This will set up your environment to use the `aws` command in this shell session only. (If you get an error, it's because your version of the AWS CLI toolkit is too old; reinstall it from the above link.)

### Create a bucket for your output.

You'll need an S3 bucket to store Rapidtide's output. You can use the [web interface](https://s3.console.aws.amazon.com/s3/buckets?region=us-east-1), or just run:

```
aws s3api create-bucket --bucket your-bucket-name
```

following the [bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html).

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
    --container-overrides command=bash,/cloud/simple-cp-test,100307
```

This will output some information about the created job. (You may need to press `q` to exit; prevent this in the future by putting `export AWS_PAGER=` in your `.bashrc`.)

Head over to the [Batch console](https://us-east-1.console.aws.amazon.com/batch) and see how it goes. 

## Run an ARRAY job

In your output bucket, create a directory called `config`, and inside it a file called `participants.txt`.[^1]  Each line of that file should be a HCP participant number.

Run:

```bash
aws batch submit-job \
    $(./batch-stack-info) \
    --job-name myFirstArrayJob \
    --array-properties size=5 \
    --container-overrides command=bash,/cloud/simple-cp-test,ARRAY
```

The number given to `size=` must be ≤ the number of lines in `participants.txt`.


[^1]: You can alter what file an array job gets participant IDs from by populating the job parameter `ParticipantArrayFile`, e.g. to run several different batches and keep track of which ones have which participants.

## Run a real job

Similar to above, but make your own shell script in your config dir and call that instead. You can use similar logic to that in `simple-cp-test` to use or not use array mode, or assume that you are in array mode and directly use the `PARTICIPANT_FROM_ARRAY` environment variable, which will be populated from your `participants.txt`.  For example:

```bash
aws batch submit-job \
    $(./batch-stack-info) \
    --job-name myFirstRealArrayJob \
    --array-properties size=5 \
    --container-overrides command=bash,/data_out/config/your-script,ARRAY
```


# Background Information

## Initial Tests, Decisions, and Reasoning

### cloud platform

Considered AWS vs. GCP vs. Azure; all important public datasets are on S3; data transfer from S3 (within AZ) is free. Using anything but AWS would be cost-prohibitive.

Within AWS, considered ParallelCluster vs Batch; landed on Batch because our desired workflow is entirely non-interactive and we've already Dockerized our software.

### accessing the data

* The `hcp-openaccess` bucket is formatted as a filesystem; it is easy to mount using [s3fs](https://github.com/s3fs-fuse/s3fs-fuse) or [goofys](https://github.com/kahing/goofys). I selected s3fs because it is more standard, and my performance tests showed no big difference between the two for our access pattern (which consists of a small number of large reads, rather than lots of back-and-forth).

* I tested whether reading the files "raw" e.g. using `aws s3 cp` or even just using `curl` would be faster; it was not, and doing so (rather than using s3fs and having a real filesystem) would be extremely complex.

* I tested whether copying the data from the bucket to local disk and *then* processing it would be faster than reading from S3 directly, and found that it was not:
  1. Our jobs are so CPU-bound that even if the network transfer portion took twice as long it would make little difference; and
  2. again, we mostly just read files in in bulk at the start, do CPU on them, then write, so pre-copying doesn't really buy us anything.

* Users are granted access to `hcp-openaccess` by being given a key/secret pair.

## How Things Work

### The container

The [Rapidtide Docker container's](https://hub.docker.com/r/fredericklab/rapidtide/tags) `ENTRYPOINT` is now `mount-and-run`, which takes the following actions:

1. Check for the existence of an environment variable that indicates the cloud environment; if it's not found, assume this is just a normal, non-cloud run of the container, and execute whatever program was requested. If is *is* found,
2. Mount the input (public dataset) and output (personal) S3 buckets on `/data_{in,out}`, using the saved credentials for the input bucket and the user's attached IAM role for the output bucket.
3. If the environment indicates an "array" type job, retrieve the participant id from the array file.

### The AWS stack

The user creates an AWS CloudFormation stack by running the `awsstack-create` script. This prompts the user for:

1. a name for the stack
2. the name of the S3 bucket to save the output data in
3. (future, not yet implemented; currently hardcoded as `hcp-openaccess`) the name of the input bucket
4. the *Access Key ID* and *Secret* for the input bucket

The script then creates the Cloudformation stack, which includes:

* a SecretsManager secret containing the input bucket key/secret
* all of the networking infrastructure needed by AWS Batch, including VPC, Internet Gateway, Route Table, Security Group, Subnet, and Route
* an IAM Role granting access to above secret and to (only) the output bucket
* a Job Definition for AWS Batch pointing to the Elastic Container Registry's copy of the Rapidtide Docker image
  * We specify Resource Requirements of 62 GB, having found that any less causes Rapidtide to fail.
* a Compute Environment
  * currently requesting either a m6g.4xlarge or r6g.2xlarge, which are Graviton (ARM) machines with 64 GB RAM and either 8 or 16 cores.
  * if Intel is wanted instead, this could be changed to "optimal" instead.

The stack requests "on demand" instances; in experimentation I found 64 GB spot instances were nearly always killed in the first 10 minutes, regardless of time of day. This can be changed easily in the stack parameters if desired; the stack includes the necessary service roles.

All of this infrastructure can be cleanly deleted in one step using the `awsstack-delete` script (or similarly with one click in the Cloudformation web console).

### Github

Whenever the Rapidtide software is updated, a new multi-architecture (arm64/amd64) Docker image is automatically built and pushed to Docker Hub, then copied to the AWS ECR. The latter is because of Docker Hub pull count restrictions; since every Batch job does an image pull, using Docker Hub would quickly exhaust the allowed daily number of pulls.

