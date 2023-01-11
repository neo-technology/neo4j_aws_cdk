#!/usr/bin/env python3
import os

import aws_cdk as cdk

from neo4j_instance.neo4j_instance import Neo4jInstanceStack


app = cdk.App()
Neo4jInstanceStack(app, "Neo4jInstanceStack")

app.synth()
