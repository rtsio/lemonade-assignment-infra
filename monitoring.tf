# S3 bucket for ALB access logs

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "lemonade-alb-access-logs"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    id                                     = "cleanup"
    enabled                                = true
    abort_incomplete_multipart_upload_days = 1
    prefix                                 = ""

    expiration {
      days = 1
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.alb_logs.arn}",
        "${aws_s3_bucket.alb_logs.arn}/*"
      ],
      "Principal": {
        "AWS": [ "${data.aws_elb_service_account.main.arn}" ]
      }
    }
  ]
}
POLICY
}


# CloudWatch dashboard with various container/ALB metrics

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "lemonade-metrics-dashboard"

  dashboard_body = <<EOF
{
   "widgets":[
      {
         "type":"metric",
         "x":12,
         "y":6,
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [
                  "AWS/ECS",
                  "MemoryUtilization",
                  "ServiceName",
                  "lemonade-assignment-service",
                  "ClusterName",
                  "lemonade-assignment-cluster",
                  {
                     "color":"#1f77b4"
                  }
               ],
               [
                  ".",
                  "CPUUtilization",
                  ".",
                  ".",
                  ".",
                  ".",
                  {
                     "color":"#9467bd"
                  }
               ]
            ],
            "region":"${var.aws_region}",
            "period":300,
            "title":"ECS resource utilization",
            "yAxis":{
               "left":{
                  "min":0,
                  "max":100
               }
            }
         }
      },
      {
         "type":"metric",
         "x":0,
         "y":0,
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":true,
            "metrics":[
               [
                  "AWS/ApplicationELB",
                  "HTTPCode_Target_5XX_Count",
                  "TargetGroup",
                  "${aws_alb_target_group.ecs_targets.arn_suffix}",
                  "LoadBalancer",
                  "${aws_alb.main.arn_suffix}",
                  {
                     "period":60,
                     "color":"#d62728",
                     "stat":"Sum"
                  }
               ],
               [
                  ".",
                  "HTTPCode_Target_4XX_Count",
                  ".",
                  ".",
                  ".",
                  ".",
                  {
                     "period":60,
                     "color":"#bcbd22",
                     "stat":"Sum"

                  }
               ],
               [
                  ".",
                  "HTTPCode_Target_2XX_Count",
                  ".",
                  ".",
                  ".",
                  ".",
                  {
                     "period":60,
                     "color":"#2ca02c",
                     "stat":"Sum"

                  }
               ]
            ],
            "region":"${var.aws_region}",
            "title":"Container HTTP status responses",
            "period":300,
            "yAxis":{
               "left":{
                  "min":0
               }
            }
         }
      },
      {
         "type":"metric",
         "x":12,
         "y":0,
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "stacked":false,
            "metrics":[
               [
                  "AWS/ApplicationELB",
                  "TargetResponseTime",
                  "LoadBalancer",
                  "${aws_alb.main.arn_suffix}",
                  {
                     "period":60,
                     "stat":"p50"
                  }
               ],
               [
                  "...",
                  {
                     "period":60,
                     "stat":"p90",
                     "color":"#c5b0d5"
                  }
               ],
               [
                  "...",
                  {
                     "period":60,
                     "stat":"p99",
                     "color":"#dbdb8d"
                  }
               ]
            ],
            "region":"${var.aws_region}",
            "period":300,
            "yAxis":{
               "left":{
                  "min":0,
                  "max":3
               }
            },
            "title":"Container response latency"
         }
      },
      {
         "type":"metric",
         "x":0,
         "y":6,
         "width":12,
         "height":6,
         "properties":{
            "view":"timeSeries",
            "metrics":[
               [
                  "AWS/ApplicationELB",
                  "HealthyHostCount",
                  "TargetGroup",
                  "${aws_alb_target_group.ecs_targets.arn_suffix}",
                  "LoadBalancer",
                  "${aws_alb.main.arn_suffix}",
                  {
                     "color":"#2ca02c",
                     "period":60
                  }
               ],
               [
                  ".",
                  "UnHealthyHostCount",
                  ".",
                  ".",
                  ".",
                  ".",
                  {
                     "color":"#d62728",
                     "period":60
                  }
               ]
            ],
            "region":"${var.aws_region}",
            "period":300,
            "stacked":false,
            "title":"ALB targets status"
         }
      }
   ]
}
EOF
}