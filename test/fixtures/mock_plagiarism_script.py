import shutil
import os
import argparse
import json

# This simple script looks for a `assessment_id` argument and returns it in a 
# json format. Meant to simulate a successful upload.
parser = argparse.ArgumentParser()
parser.add_argument("--assessment_id", type=int, default=16, help="assessment id to generate plagiarism reports")

args = parser.parse_args()
assessment_id = int(args.assessment_id)
assessments_path = "submissions/assessment{}".format(assessment_id)

if os.path.isdir(assessments_path):
    shutil.rmtree(assessments_path)
os.makedirs(assessments_path)
os.makedirs(assessments_path + "/report")
file = open(assessments_path + "/assessment_report_{}.html".format(assessment_id), "w")
file.write("test")

print(json.dumps({'assessment_id':assessment_id}))
