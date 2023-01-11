from aws_cdk import (
    Stack,
    CfnOutput,
    aws_s3 as s3,
    aws_ec2 as ec2,
    aws_elasticloadbalancingv2 as elb,
    aws_elasticloadbalancingv2_targets as elb_targets,
    aws_cloudfront as cloudfront,
    aws_cloudfront_origins as cloudfront_origins,
    aws_certificatemanager as certificatemanager,
    aws_iam as  iam,
)
from constructs import Construct

class Neo4jInstanceStack(Stack):

    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        backup_bucket = s3.Bucket(self, 'neo4j-backup')
        CfnOutput(self, 'Neo4jBackupBucket', value=backup_bucket.bucket_name)

        vpc = ec2.Vpc(self, "WHO-VPC", 
            subnet_configuration=[
                ec2.SubnetConfiguration(name="public", subnet_type=ec2.SubnetType.PUBLIC)
            ]
        )

        security_group = ec2.SecurityGroup(self, 'neo4jSecurityGroup',
                                           vpc=vpc,
                                           allow_all_outbound=True,
                                           description='security group for neo4j instance'
                                           )
        security_group.add_ingress_rule(
            ec2.Peer.any_ipv4(),
            ec2.Port.tcp(7473),
            description='allow inbound from anywhere on neo4j browser'
        )
        security_group.add_ingress_rule(
            ec2.Peer.any_ipv4(), 
            ec2.Port.tcp(7687), 
            description='allow inbound from  anywhere on neo4j/bolt protocol'
        )
        security_group.add_ingress_rule(
            ec2.Peer.any_ipv4(), 
            ec2.Port.tcp(80), 
            description='allow inbound from  anywhere for domain cerification (certbot)'
        )

        role = iam.Role(self, "neo4jInstanceSSM",
                        assumed_by=iam.ServicePrincipal("ec2.amazonaws.com"))
        role.add_managed_policy(iam.ManagedPolicy.from_aws_managed_policy_name(
            "AmazonSSMManagedInstanceCore"))

        with open("./neo4j_instance/neo4j_setup_script.sh") as f:
            neo4j_setup_script= f.read()
        commandsUserData = ec2.UserData.for_linux()
        commandsUserData.add_commands(neo4j_setup_script)

        neo4j_instance = ec2.Instance(
            self,
            "neo4j-instance",
            vpc=vpc,
            instance_type=ec2.InstanceType.of(
                ec2.InstanceClass.T4G, 
                ec2.InstanceSize.XLARGE),
            role=role,
            security_group=security_group,
            user_data=commandsUserData,
            machine_image=ec2.AmazonLinuxImage(
                generation=ec2.AmazonLinuxGeneration.AMAZON_LINUX_2,
                cpu_type=ec2.AmazonLinuxCpuType.ARM_64
            ),
            block_devices=[
                ec2.BlockDevice(device_name='/dev/sdm', volume=ec2.BlockDeviceVolume.ebs(500)),
            ]
        )
        backup_bucket.grant_read_write(neo4j_instance)
        CfnOutput(self, 'Neo4jInstanceId', value=neo4j_instance.instance_id)
        CfnOutput(self, 'Neo4jPublicDnsName', value=neo4j_instance.instance_public_dns_name)

        elastic_ip = ec2.CfnEIP(self, 'neo4j-instance-ip')
        ec2.CfnEIPAssociation(self, 'neo4j-instance-ip-association', eip=elastic_ip.ref, instance_id=neo4j_instance.instance_id)
        CfnOutput(self, 'Neo4jElasticIp', value=elastic_ip.attr_public_ip)

