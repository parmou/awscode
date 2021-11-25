resource "aws_iam_role" "ec2-s3-access-profile" {
    name                  = "ec2-s3-access-profile"
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = "ec2.amazonaws.com"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    description           = "Allows EC2 instances to call AWS services on your behalf."
    force_detach_policies = false
    managed_policy_arns   = [
        "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    ]
    max_session_duration  = 3600
   
    path                  = "/"
    tags                  = {
        "Name" = "ec2-s3-access-profile"
    }
    tags_all              = {
        "Name" = "ec2-s3-access-profile"
    }

    inline_policy {}
}


resource "aws_iam_instance_profile" "ec2-s3-access-profile" {
  
    name        = "ec2-s3-access-profile"
    path        = "/"
    role        = aws_iam_role.ec2-s3-access-profile.name
    tags        = {}
    tags_all    = {}

}