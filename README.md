# Project - *Web Application - Infrastructure as Code* - Network Structures and Cloud Computing

**Web Application - Infrastructure as Code** is a project which deploys applications by launching the AMI using Amazon Linux 2 via **Packer**, setup autorun using **Systemd**, and using **Terraform** configuration file to create all AWS resources needed.

Submitted by: **Zhengrui Lu**

Time spent: **80** hours spent in total

## User Stories

The following **required** functionality is completed:

### Web Application
* [X] Completed [Product Management Application](https://github.com/ZhengruiLu/webapp).

### Infrastructure as Code with Terraform and Packer
* [X] Deployed Application by launching the AMI using Amazon Linux 2 via **Packer**. 
* [X] Setup autorun using **Systemd**.
* [X] Used Terraform configuration file to create all AWS resources needed, such as all networking resources, IAM, and S3 bucket. Domain Name System(DNS) Updates - Route53 resource record. Reduced launch time by 40%.
* [X] Set up the application’s database as the Encrypted RDS instance when running on the EC2 instances, which are launched in an auto-scaling group. Created an Application load balancer to accept HTTPS traffic on port 443.
* [X] Set logging using CloudWatch. Retrieved custom metrics with StatsD. Resolving issues promptly.

### CI/CD with [Github Action](https://github.com/ZhengruiLu/webapp/tree/main/.github/workflows)
* [X] Pull Request Raised Workflow.
	* [X] Add a GitHub Action workflow to run the application unit tests for each pull request raised.
    * [X] A pull request can only be merged if the workflow executes successfully.
* [X] Pull Request Merged Workflow.
	* [X] Add another GitHub actions workflow and configure it to be triggered when a pull request is merged. This workflow should do the following:
		- a. Run the unit test.
		- b. Validate Packer Template
		- c. Build Application Artifact(s)
		- d. Build AMI
			- i. Upgrade OS packages
			- ii. Install dependencies (python, node.js, etc.)
			- iii. Install application dependencies (pip install for Python)
			- iv. Set up the application by copying the application artifacts and the configuration files.
			- v. Configure the application to start automatically when VM is launched.
		- e. Create a new Launch Template version with the latest AMI ID for the autoscaling group. The autoscaling group should be configured to use the latest version of the Launch Template.
		- f. Issue command to the auto-scale group to do an instance refresh.

## Notes
Describe any challenges encountered while building the app.

### Web Application Dev
* [X] CI/CD for Web Application.

### Cloud
* [X] Understand the functions and application methods of AWS-related services.
* [X] Test auto-scaling group and load balancer

## License

    Copyright [yyyy] [name of copyright owner]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
