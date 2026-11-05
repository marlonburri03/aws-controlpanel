# Retrospective

## Technical conclusion

The project provides a stable basis for managing AWS resources automatically. The control panel creates, configures and deletes resources efficiently; the modular script structure and guided input make working with AWS infrastructure noticeably easier and show the advantage of automated over manual processes.

Looking more closely, there are open questions about scalability and long-term operation. The goal of working completely without the web console was reached, but only by restricting some parameters or giving them defaults, for example the SSH key pair or the AWS region. As development took place in an isolated lab account, it remains open how well the tool would perform in a production environment and how much value it would add there.

Reducing the number of options improved usability considerably. Some parameters still have to be entered manually because no sensible default exists. Predefined profiles or dynamic lookups of existing resources would be the next improvements.

**Alternatives considered critically:** Bash and the AWS CLI were chosen because shell automation was the focus of the semester. For production use, a declarative tool such as Terraform or the AWS CDK would offer state tracking, plan/apply and idempotency, which a script-based approach has to implement by hand. A language such as Python with the AWS SDK would make input validation and error handling easier than Bash.

## Personal conclusion

The project was demanding and a good opportunity to grow. Building the control panel deepened my understanding of automating cloud resources with the AWS CLI and Bash. Building a usable tool required not only technical know-how but also a feeling for process design and user guidance.

A key insight was the importance of clear boundaries, for example when choosing availability zones or deciding which resources to automate. Careful planning and an iterative, step-by-step approach kept complex requirements manageable and led to a stable result.

The project also showed limits: more time would have allowed work on scalability and further independence from the web console. Working through these technical and planning challenges strengthened perseverance, problem solving and structured thinking.

## Next steps

- **Role-based access:** user and permission management to make the tool usable in a team.
- **Reporting:** a daily summary of created and deleted resources by e-mail, in addition to the log file.
- **More services:** S3, RDS or IAM, and scaling features for environments with several instances, subnets or load balancers.
- **Declarative infrastructure:** integration with Terraform for repeatable, versioned and reviewable deployments, combined with a CI/CD pipeline that tests and releases the scripts.
