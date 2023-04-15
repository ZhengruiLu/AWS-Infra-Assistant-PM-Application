# Move all IAM roles and policies
resource "aws_iam_policy" "webapp_s3_policy" {
  name = "webapp-s3-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowGroupToSeeBucketListInTheConsole",
        "Effect" : "Allow",
        "Action" : ["s3:ListBucket", "s3:GetBucketLocation"],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*"
        ]
      },
      {
        "Sid" : "AllowUserSpecificActionsOnlyInTheSpecificUserPrefix",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectAcl",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.private_bucket.bucket}/*"
        ]
      }
    ]
  })
}

# 2.7 IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "EC2-CSYE6225"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2 Role for CSYE6225"
  }
}

resource "aws_iam_policy_attachment" "ec2_policy_attachment" {
  name       = "ec2_policy_attachment"
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
  roles      = [aws_iam_role.ec2_role.id]
}

# add cloudwatch_agent_policy
resource "aws_iam_policy_attachment" "cloudwatch_agent_policy_attachment" {
  name       = "cloudwatch_agent_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  roles      = [aws_iam_role.ec2_role.id]
}

