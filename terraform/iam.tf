resource "aws_iam_role" "ec2_role" {
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_attach" {
  for_each = toset([
    "AmazonEC2ContainerRegistryFullAccess",
    "AmazonEC2FullAccess",
    "AmazonS3FullAccess",
    "EC2InstanceConnect",
  ])

  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}